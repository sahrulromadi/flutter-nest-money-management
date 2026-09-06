# 029 — Semua Fitur Local-First (Goals, Recurring, Insights, Reminders)

Status: Draft — belum dikerjakan
Sumber: user. BE jarang dinyalain (jalan di laptop) → semua yang REST-only praktis mati.
Fitur inti app = offline-first (PRD NFR).

## Audit: apa yang belum local-first
| Fitur | Status sekarang | Item |
|---|---|---|
| Akun, Kategori, Transaksi, Home | ✅ local-first (Drift + sync) | — |
| **Goals** | ❌ REST-only, hard gate "Login dulu" | Item 1 |
| **Transaksi Berulang** | ❌ REST-only + scheduler di BE (ga pernah jalan) | Item 2 |
| **Insights** (budget + laporan/grafik) | ❌ REST-only, hard gate "Login dulu" | Item 3 |
| **Reminders** (notif tagihan) | ❌ fetch `/reminders/upcoming-bills` tiap app buka (silent fail) | Item 4 |

Infra lokal (Drift tables, DAOs, serializer sync, `sync.constants`) **udah ada semua** buat
goals / recurring_rules / budget_periods / budgets — cuma UI-nya nge-bypass ke REST.
**Gak ada perubahan schema.**

Login abis ini **cuma perlu buat Sync** (push/pull ke Postgres). Semua fitur jalan offline.

## Kondisi sekarang
- `goals_providers` / `recurring_providers` → `*Api` (REST `/goals`, `/recurring-rules`),
  butuh JWT. Screen-nya nampilin gate "Login dulu" kalau belum unlocked.
- Infra lokal **udah ada tapi ga dipake UI**: `GoalsDao`, `RecurringRulesDao`
  (`watchAll`/`upsert`/`softDelete`/`pendingSync`), serializer sync, `sync.constants`
  udah masukin `goals` + `recurring_rules`. Tabel Drift udah ada.
- BE scheduler: `recurring-rules.scheduler.ts` — `@Cron('0 1 * * *')` →
  `generateDueTransactions()` (cari rule `next_run_date <= CURRENT_DATE`, bikin transaksi,
  dorong `next_run_date`). Cron in-process `@nestjs/schedule`, mati kalau proses mati.

**Gak ada perubahan schema** — semua tabel & kolom udah ada di dua sisi.

---

## Item 1 — Goals local-first

### Mobile
- `mobile/lib/data/repository/goals_repository.dart` (baru) — mirror `CategoriesRepository`:
  - `watchAll(userId)` → `GoalsDao.watchAll`
  - `create({ userId, name, targetAmount, dueDate, accountId })` → `upsert` (UUID client,
    `pendingSync` default true)
  - `delete(id)` → `softDelete`
  - `watchProgress(goalId)` → stream dari `TransactionsDao`: `SUM(amount) WHERE goal_id = X
    AND deleted_at IS NULL`. Tambah method `TransactionsDao.watchGoalTotal(goalId)`.
- `GoalsDao` — tambah `updateFields(id, companion)` (buat edit nanti; kalau form belum
  support edit, skip).
- `mobile/lib/features/goals/goals_providers.dart` — ganti `goalsApiProvider` →
  `goalsRepositoryProvider` (Drift). `goalsListProvider` = `StreamProvider` dari `watchAll`.
  Provider baru `goalProgressProvider.family` buat SUM per goal.
- `goals_list_screen.dart`:
  - **hapus gate `AuthPhase.unlocked`** + `AppLoginRequiredState`.
  - progress bar & angka dari `goalProgressProvider` (bukan `g.percentage`/`g.currentAmount`
    dari DTO). Hitung `percentage = (total / target * 100)`.
  - tambah swipe-to-delete (opsional, biar ada cara hapus goal — sekarang gak ada).
- `goal_form_screen.dart` — `goalsApiProvider` → `goalsRepositoryProvider`. (udah pakai
  `MoneyField` dari plan 028). Butuh `userId` dari `currentUserIdProvider`.
- `mobile/lib/data/remote/goals_api.dart` — **dihapus** (atau dibiarin unused; default: hapus
  + bersihin import).
- Cara nandain transaksi kontribusi ke goal: `transactions.goal_id` udah ada di
  `transaction_form_screen` (`_goalId`, dropdown "Goal"). Cek dropdown itu baca dari provider
  goals lokal yang baru — sesuaikan.

### Backend
- **Gak diubah.** Endpoint `/goals` tetap ada (Swagger/manual), mobile ga pake lagi.
  Sync `goals` udah jalan (`sync.constants` + serializer).
- Cek: `goalToJson`/`goalFromJson` di `sync_serializers.dart` udah bener buat semua kolom.

### Verifikasi Item 1
1. `flutter analyze` clean, `build_runner` ok.
2. Tanpa login: buka Goals → **gak ada** gate login, bisa bikin goal, muncul di list.
3. Bikin transaksi, tag ke goal → progress bar goal naik (real-time, dari SUM lokal).
4. Hapus transaksi yang di-tag → progress turun.
5. Hapus goal → ilang dari list; transaksi yang nge-tag goal itu tetap ada (`goal_id`
   nunjuk row kehapus — aman, cuma ga keitung di progress goal lain).
6. Sync → goal masuk Postgres; `GET /goals` konsisten.

---

## Item 2 — Recurring local-first + generator di mobile

### Mobile — CRUD lokal
- `mobile/lib/data/repository/recurring_rules_repository.dart` (baru):
  - `watchAll(userId)` → DAO
  - `create({ userId, accountId, categoryId, type, amount, note, intervalUnit,
    intervalValue, startDate, endDate })` → `upsert`. `next_run_date` awal = `startDate`.
  - `delete(id)` → `softDelete`
- `recurring_providers.dart` — `recurringRulesApiProvider` → `recurringRulesRepositoryProvider`
  (Drift). `recurringRulesListProvider` = `StreamProvider` dari `watchAll`.
- `recurring_list_screen.dart` — hapus gate login (kalau ada), pakai provider lokal.
- `recurring_form_screen.dart` — pakai repo lokal + `currentUserIdProvider`. (udah pakai
  `MoneyField` plan 028).
- `mobile/lib/data/remote/recurring_rules_api.dart` — dihapus / unused (default: hapus).

### Mobile — generator (pengganti BE cron)
- `RecurringRulesDao` tambah:
  - `findDue(userId, DateTime today)` — `WHERE deleted_at IS NULL AND next_run_date <= today
    AND (end_date IS NULL OR end_date >= next_run_date)`
  - `advanceNextRun(id, DateTime next, DateTime now)` — set `next_run_date = next`,
    `updated_at = now`, `pending_sync = true`
- `TransactionsDao` tambah:
  - `existsForRule(ruleId, DateTime occurredAt)` → bool (guard anti-dobel; `deleted_at`
    diabaikan? — kalau user hapus transaksi recurring, jangan di-generate ulang → cek
    **termasuk yang deleted**). Pertimbangan: user hapus 1 instance recurring = sengaja,
    jangan muncul lagi. Jadi guard cek semua row (deleted included) `recurring_rule_id = X
    AND occurred_at = D`.
- `mobile/lib/data/recurring/recurring_generator.dart` (baru) — `RecurringGenerator`:
  ```
  Future<int> run(String userId) async {
    final today = DateUtils.dateOnly(DateTime.now());
    var generated = 0;
    for (final rule in await _recurringDao.findDue(userId, today)) {
      var next = rule.nextRunDate;
      while (!next.isAfter(today) &&
             (rule.endDate == null || !next.isAfter(rule.endDate!))) {
        if (!await _txnDao.existsForRule(rule.id, next)) {
          await _txnDao.upsert(/* Transaction: recurringRuleId=rule.id,
            occurredAt=next, accountId, categoryId, type, amount, note,
            pendingSync=true, id=uuid */);
          generated++;
        }
        next = _computeNext(next, rule.intervalUnit, rule.intervalValue);
      }
      await _recurringDao.advanceNextRun(rule.id, next, DateTime.now().toUtc());
    }
    return generated;
  }

  DateTime _computeNext(DateTime from, String unit, int value) => switch (unit) {
    'Day'  => from.add(Duration(days: value)),
    'Week' => from.add(Duration(days: value * 7)),
    'Month'=> _addMonthsClamped(from, value),  // 31 Jan +1bln -> 28/29 Feb (PRD #9)
    _ => from,
  };
  ```
- **Trigger** (DIPUTUSKAN): **pas app launch aja**, setelah DB siap + `userId` diketahui.
  Habit user = buka app tiap hari + selalu cold-close, jadi launch-only cukup. **Ga** pakai
  `WidgetsBindingObserver` / app-resume. Titik pasti: bootstrap flow yang udah ada di
  `main.dart` (deket `reminderScheduler.refresh()` yang existing) — best-effort, jangan
  bikin app crash / delay startup (jalanin async, ga di-await sebelum first frame).
- **Catch-up** (DIPUTUSKAN): generate **semua** instance kelewat, **tanpa cap**. Habit user
  = harian, jadi paling telat 1-2 hari. `while` loop jalan sampai `next_run_date > today`.
  Transaksi bertanggal mundur sesuai jadwal asli.

### Backend
- `backend/src/recurring-rules/recurring-rules.scheduler.ts` — **hapus** (atau hapus
  `RecurringRulesScheduler` dari `providers` di `recurring-rules.module.ts`). Generator
  pindah ke mobile, BE jarang nyala jadi cron ga guna + risiko dobel.
- `ScheduleModule.forRoot()` di `app.module.ts` — cek ada consumer lain (reminders?).
  `reminders` kelihatannya cuma query (`reminders.repository`), ga ada `@Cron`. Kalau
  emang ga ada consumer → boleh hapus `ScheduleModule` + `@nestjs/schedule` dari deps.
  Kalau ragu, biarin (harmless).
- `generateDueTransactions()` di service — boleh dibiarin (dead code, ga kepanggil) atau
  dihapus. Default: hapus method + scheduler, sisain CRUD.
- Endpoint REST `/recurring-rules` CRUD — **tetap** (Swagger/manual). `next_run_date`
  advance via mobile sekarang; kalau ada yang bikin rule via REST, `next_run_date` awal =
  `start_date` (udah gitu di `recurring-rules.repository` insert).
- **Dedup lintas-device**: guard `existsForRule` di mobile cek by `(recurring_rule_id,
  occurred_at)`. Kalau ada transaksi recurring dari BE (era lama) yang ke-pull, mobile
  skip generate buat tanggal itu. Aman.

### Verifikasi Item 2
1. `flutter analyze` + `build_runner` ok. Backend `build` + `eslint` clean (abis hapus scheduler).
2. Tanpa login: buka Transaksi Berulang → bisa bikin rule (mis. "Gaji", tiap 1 bulan,
   mulai kemarin) → muncul di list.
3. Restart app → generator jalan → transaksi "Gaji" ke-generate tanggal `start_date`,
   `next_run_date` maju 1 bulan. Muncul di list Transactions, ditandai dari recurring.
4. Restart lagi (tanggal belum lewat) → **ga** generate dobel.
5. Rule harian, `start_date` 5 hari lalu, app baru dibuka → 5 transaksi ke-generate
   (tanggal mundur), `next_run_date` = besok.
6. Hapus 1 transaksi recurring → restart → transaksi itu **ga** muncul lagi (guard cek
   termasuk deleted).
7. `end_date` kelewat → generator berhenti di `end_date`, ga generate lebih.
8. Edge: rule bulanan `start_date` 31 Jan → next = 28/29 Feb (bukan error / 3 Mar).
9. Sync → rule + transaksi hasil generate masuk Postgres; `GET /recurring-rules` konsisten.
10. BE: `npm run start` → **ga ada** cron jalan jam 01:00 (log bersih), ga ada transaksi
    dobel setelah sync.

---

## Item 3 — Insights (budget + laporan) local-first

Budget periods, budgets, dan semua laporan (summary, breakdown kategori, cashflow trend)
sekarang REST (`/budget-periods`, `/budgets`, `/reports/*`). Semuanya bisa dihitung dari
tabel `transactions` lokal.

### Mobile — budget
- `mobile/lib/data/repository/budget_repository.dart` (baru):
  - `watchActivePeriod(userId)` → `BudgetPeriodsDao.findActive` (jadiin stream / `watchAll`
    lalu `firstWhereOrNull(endedAt == null)`).
  - `watchAllPeriods(userId)` → `BudgetPeriodsDao.watchAll`.
  - `startNewPeriod(userId, startedAt)` → tutup periode aktif (`ended_at = startedAt - 1
    hari`, `pending_sync`), insert periode baru (`ended_at = null`). Dalam 1 transaksi Drift.
  - `watchBudgets(periodId)` → `BudgetsDao.watchByPeriod`.
  - `setBudget({ periodId, categoryId, limitAmount })` → upsert (unik per
    `(period, category)` — cek existing by query, update kalau ada).
  - `deleteBudget(id)` → `softDelete`.
  - `watchSpent(period, categoryId)` → stream SUM dari `TransactionsDao`: `type='Expense'
    AND category_id=X AND occurred_at BETWEEN period.startedAt AND
    COALESCE(period.endedAt, today)`.
- `BudgetPeriodsDao` — tambah `updateFields` (buat nutup periode), `watchActive`.
- `BudgetsDao` — tambah `findByPeriodAndCategory(periodId, categoryId)` (buat upsert unik).
- `TransactionsDao` — tambah `watchExpenseByCategoryInRange(catId, from, to)` (SUM stream).

### Mobile — laporan (semua dari Drift, ganti `/reports/*`)
- Provider baru di `insights_providers.dart`, hitung dari `TransactionsDao`:
  - **summary** (total income/expense periode aktif): `SUM(amount) FILTER type` di range.
  - **category breakdown** (Expense per kategori): `GROUP BY category_id` join nama
    kategori lokal, `type='Expense' AND category_id NOT NULL` di range. (transaksi
    tanpa kategori — penyesuaian/biaya transfer plan 028 — otomatis ke-exclude, sama kaya
    BE INNER JOIN.)
  - **cashflow trend** (harian): `GROUP BY occurred_at` income vs expense di range.
- Range default = periode budget aktif; kalau belum ada periode → fallback bulan kalender
  berjalan (biar laporan tetap ada sebelum user mulai periode pertama).

### Mobile — screen
- `insights_screen.dart` + `budget_form_sheet.dart`:
  - **hapus gate `AuthPhase.unlocked`** + `AppLoginRequiredState`.
  - semua `ref.watch(*ApiProvider ...)` → provider Drift baru.
  - `RefreshIndicator` `onRefresh` → cukup `ref.invalidate` provider lokal (atau biarin,
    stream auto-update — `RefreshIndicator` bisa jadi cuma UX no-op).
- `budget_form_sheet.dart` udah pakai `MoneyField` (plan 028) + `categoriesListProvider`
  lokal — tinggal ganti `budgetApiProvider.createBudget` → `budgetRepository.setBudget`.

### Backend
- **Gak diubah.** `/budget-periods`, `/budgets`, `/reports/*` tetap ada (Swagger/manual),
  mobile ga pake. Sync `budget_periods` + `budgets` udah jalan.
- `reports` module: murni read/agregasi, ga ada state — biarin.

### Verifikasi Item 3
1. `flutter analyze` + `build_runner` ok.
2. Tanpa login: buka Insights → **gak ada** gate login.
3. Belum ada periode budget → laporan tetap tampil (range = bulan berjalan), bagian budget
   kasih CTA "Mulai periode".
4. "Mulai periode baru" → periode aktif kebuat; periode lama (kalau ada) ke-tutup
   (`ended_at` = sehari sebelum).
5. Set budget kategori → progress bar (spent/limit) dari SUM transaksi lokal, real-time
   pas ada transaksi Expense baru di kategori itu.
6. Breakdown & trend cocok sama data transaksi lokal; transaksi tanpa kategori ga muncul
   di breakdown, tapi keitung di trend/summary.
7. Sync → periode + budget masuk Postgres; `GET /budgets` konsisten.

---

## Item 4 — Reminders local-first (turunan Item 2)

`ReminderScheduler.refresh()` (dipanggil di `main.dart` tiap app buka) fetch
`/reminders/upcoming-bills` (= recurring rules yang `next_run_date` dalam N hari) buat
jadwalin local notification. Butuh backend nyala.

### Keputusan
Begitu recurring local-first (Item 2), "upcoming bills" bisa di-query dari
`RecurringRulesDao` lokal. Buang dependency `RemindersApi`.

### Scope — Mobile only
- `RecurringRulesDao` — tambah `findUpcoming(userId, DateTime until)` — `WHERE deleted_at
  IS NULL AND next_run_date <= until AND (end_date IS NULL OR end_date >= next_run_date)`.
- `mobile/lib/features/reminders/reminder_scheduler.dart`:
  - `_scheduleBills()` → ganti `_api.upcomingBills(withinDays: 3)` jadi
    `_recurringDao.findUpcoming(userId, today + 3 hari)`. Map ke notif yang sama.
  - `remindersApiProvider` + import `reminders_api.dart` → dihapus.
  - `ReminderScheduler` ctor: `RemindersApi` → `RecurringRulesDao` + `userId` source.
- `main.dart` — `reminderScheduler.refresh()` tetap dipanggil (sekarang murni lokal,
  ga butuh network / login).

### Backend
- Endpoint `/reminders/*` + `reminders` module — **boleh dihapus semua** (mobile satu-satunya
  konsumen, sekarang lokal). Default: hapus `backend/src/reminders/` + daftar di
  `app.module.ts`. Kalau mau simpen buat kemungkinan konsumen lain → biarin (dead-ish).

### Verifikasi Item 4
1. `flutter analyze` ok. Backend `build` clean (abis hapus reminders module).
2. Bikin recurring rule tipe Expense (tagihan) `next_run_date` 2 hari lagi, reminder ON
   di Settings → app buka → notif "Tagihan jatuh tempo besok" ke-schedule (H-1 jam 09:00).
   Tanpa login / backend nyala.
3. Reminder OFF di Settings → ga ada notif ke-schedule.

---

## Dead code yang dihapus (semua item)

### Mobile
- `mobile/lib/data/remote/goals_api.dart` (Item 1)
- `mobile/lib/data/remote/recurring_rules_api.dart` (Item 2)
- `mobile/lib/data/remote/budget_api.dart` + `reports_api.dart` (Item 3)
- `mobile/lib/data/remote/reminders_api.dart` (Item 4)
- provider `*ApiProvider` yang jadi yatim di tiap `*_providers.dart`
- `AppLoginRequiredState` — cek masih dipake di tempat lain; kalau enggak, hapus dari
  `app_illustration.dart`.
- `widget_test.dart` — udah stale (expect Login di boot, `pumpAndSettle` timeout). Ganti
  jadi test yang relevan atau hapus. (out of scope teknis, tapi sekalian.)

### Backend
- `backend/src/recurring-rules/recurring-rules.scheduler.ts` + registrasi di module (Item 2)
- `RecurringRulesService.generateDueTransactions()` + `computeNextRunDate()` (Item 2)
- `RecurringRulesRepository.findDueRules()` + `advanceNextRunDate()` — cek dipake service
  lain; kalau cuma scheduler → hapus.
- `backend/src/reminders/` seluruh module + `app.module.ts` entry (Item 4)
- `ScheduleModule.forRoot()` + `@nestjs/schedule` dependency — kalau abis hapus scheduler
  ga ada `@Cron`/`@Interval` lain → hapus. (grep dulu pas eksekusi.)
- Endpoint REST yang disisain: `/goals`, `/recurring-rules`, `/budget-periods`, `/budgets`,
  `/reports/*` — **TETAP** (Swagger + jaga-jaga). Cuma generator/scheduler/reminders yang
  dibuang.

---

## Out of Scope
- Edit rule recurring yang udah jalan (ubah interval/nominal) — kalau form belum support,
  skip; hapus + bikin baru.
- Re-run generator pas app resume (launch-only, sesuai habit user).
- Recurring buat tipe Transfer (sekarang cuma Income/Expense — sesuai schema).
- Nyimpen `/reports/*` sebagai sumber kebenaran (mobile jadi sumber, BE cuma mirror via sync).

## Urutan eksekusi
1. Item 1 (Goals) — paling kecil, pola bersih buat item lain.
2. Item 2 (Recurring + generator) — inti.
3. Item 4 (Reminders) — turunan Item 2, kecil.
4. Item 3 (Insights) — paling gede, sendiri.
Tiap item = commit sendiri.

# 030 — Rename `budget_periods` → `periods` + Laporan per Periode

Status: **SELESAI** (2026-09-06). Item 1 `a5e60c9`, Item 2 `29a850b`.
- Item 1: rename backend (migrasi Postgres + folder/class + endpoint `/periods`) + mobile
  (Drift tables/daos/serializers + build_runner regen). Drift `MigrationStrategy` DIHAPUS,
  `schemaVersion` balik ke 1 — APK fase dev, uninstall+install ulang tiap ubah schema.
- Item 2: selector periode + "Ringkasan per Periode" + laporan re-scope ke periode terpilih
  + budget read-only buat periode ditutup.
- Belum diverifikasi di device.
Sumber: user.
- Periode itu konsep time-boxing umum (siklus gajian) yang nge-scope **semua** laporan
  (income/expense/breakdown/cashflow), bukan cuma budget. Nama `budget_periods` bikin
  kesannya khusus budget. → rename jadi `periods`.
- User mau lihat income & pengeluaran **per periode** (periode 1, 2, 3, …), bukan cuma
  periode aktif.

**Data buat laporan per periode udah ada semua** — `TransactionsDao.watchSummary(userId,
from, to)` udah nerima rentang bebas, `BudgetPeriodsDao.watchAll` udah kasih semua periode.
Yang kurang cuma provider + UI. Rename = kosmetik tapi nyentuh banyak file + 1 migrasi.

---

## Item 1 — Rename `budget_periods` → `periods`

Termasuk kolom FK `budgets.budget_period_id` → `budgets.period_id` biar konsisten.

### Backend
- Migrasi baru:
  ```sql
  -- up
  ALTER TABLE budget_periods RENAME TO periods;
  ALTER TABLE budgets RENAME COLUMN budget_period_id TO period_id;
  ALTER INDEX IF EXISTS idx_budget_periods_user_id RENAME TO idx_periods_user_id;  -- kalau ada
  -- down: kebalikannya
  ```
  (cek nama index/constraint aktual di `\d budget_periods` + `\d budgets` dulu — FK constraint
  `budgets_budget_period_id_fkey` ikut ke-rename otomatis? Postgres **nggak** auto-rename
  constraint pas rename kolom. Rename manual biar rapi:
  `ALTER TABLE budgets RENAME CONSTRAINT budgets_budget_period_id_fkey TO budgets_period_id_fkey;`)
- Rename folder `backend/src/budget-periods/` → `backend/src/periods/`, file + class:
  - `BudgetPeriodsController` → `PeriodsController`, `@Controller('budget-periods')` →
    `@Controller('periods')`
  - `BudgetPeriodsService` → `PeriodsService`
  - `BudgetPeriodsRepository` → `PeriodsRepository`, tabel di SQL `budget_periods` → `periods`
  - `BudgetPeriodsModule` → `PeriodsModule`
  - `CreateBudgetPeriodDto` → `CreatePeriodDto`
- `backend/src/budgets/budgets.repository.ts` — `budget_period_id` → `period_id` di semua SQL.
- `backend/src/reports/*` — `budget_period` refs (cek: reports pakai periode buat scope?).
- `backend/src/app.module.ts` — `BudgetPeriodsModule` → `PeriodsModule`.
- `backend/src/sync/sync.constants.ts`:
  - entri `name: 'budget_periods'` → `'periods'`
  - entri `budgets`: kolom `budget_period_id` → `period_id`, `userScopeWhere`
    `budget_period_id IN (SELECT id FROM budget_periods ...)` → `period_id IN (SELECT id FROM periods ...)`
  - **urutan `SYNC_TABLES`**: `periods` harus tetap sebelum `budgets` (FK).

### Mobile
- `mobile/lib/data/local/tables/budget_periods.dart` → `periods.dart`, class `BudgetPeriods`
  → `Periods`, `@DataClassName('Period')` (default-nya `Periode`? cek — "Periods" →
  singularize → "Period", aman, tapi kasih eksplisit).
- `budgets.dart` — `budgetPeriodId` → `periodId`, `.named('budget_period_id')` →
  `.named('period_id')`.
- `mobile/lib/data/local/app_database.dart`:
  - `@DriftDatabase(tables: [... BudgetPeriods ...])` → `Periods`
  - `daos: [... BudgetPeriodsDao ...]` → `PeriodsDao`
  - `schemaVersion` naik (mis. 2 → 3), `onUpgrade`:
    ```dart
    if (from < 3) {
      await m.renameTable(budgetPeriods, 'budget_periods'); // API: renameTable(newTable, oldName)
      await m.renameColumn(budgets, 'budget_period_id', budgets.periodId);
    }
    ```
    (cek signature `Migrator.renameTable` / `renameColumn` di versi drift yang dipakai —
    mungkin butuh `customStatement('ALTER TABLE ... RENAME ...')` kalau API beda.)
- rename `daos/budget_periods_dao.dart` → `periods_dao.dart`, `BudgetPeriodsDao` →
  `PeriodsDao`, semua `budgetPeriods` → `periods`.
- `daos/budgets_dao.dart` — `budgetPeriodId` → `periodId`.
- `mobile/lib/data/sync/sync_serializers.dart`:
  - `budgetPeriodToJson`/`FromJson` → `periodToJson`/`FromJson`, key `'started_at'` dst tetap;
    tabel refs.
  - budget serializer: `'budget_period_id'` → `'period_id'`, `.budgetPeriodId` → `.periodId`.
- `mobile/lib/data/sync/sync_engine.dart` — key `'budget_periods'` → `'periods'` di map
  push/pull, `budgetPeriodsDao` → `periodsDao`.
- `mobile/lib/data/repository/budget_repository.dart` — `_periodsDao` tipe, method names OK.
- `mobile/lib/features/insights/*` — `BudgetPeriod` tipe → `Period`, `activeBudgetPeriodProvider`
  boleh tetap namanya atau → `activePeriodProvider` (rename provider = churn kecil, lakuin).
- regenerate build_runner.

### Docs
- `docs/SCHEMA.md` — section `## budget_periods` → `## periods`, `budgets.budget_period_id`
  → `period_id`.
- `docs/PRD.md` §4 — "BudgetPeriod" → "Period".

### Verifikasi Item 1
1. Backend: `migrate:up` → `\d periods` ada, `\d budgets` kolom `period_id`, data lama utuh
   (count row sama). `migrate:down` balik. `nest build` + `eslint` clean.
2. Swagger: endpoint `/periods` (bukan `/budget-periods`).
3. Mobile: `flutter analyze` clean, `build_runner` ok, semua test pass.
4. Upgrade in-place (data lama ada periode + budget): app buka, Insights nampilin periode
   aktif + budget-nya bener, no crash.
5. Sync: push/pull periode + budget → Postgres tabel `periods` / `budgets.period_id`, no error.

---

## Item 2 — Laporan per periode (income/expense/breakdown/cashflow)

User mau lihat pemasukan & pengeluaran tiap periode (1, 2, 3, …), plus bisa buka laporan
periode lama (read-only) — sesuai PRD §5 Rilis 2 yang belum kebangun.

### Mobile — providers (`insights_providers.dart`)
- `allPeriodsProvider` → `StreamProvider<List<Period>>` dari `PeriodsDao.watchAll` (udah ada,
  urut `started_at DESC`).
- `selectedPeriodProvider` → `StateProvider<String?>` (id periode; null = aktif). Default null.
- `reportRangeProvider` → ubah: pakai periode terpilih.
  - periode aktif → `to = hari ini`
  - periode ditutup → `to = period.ended_at`
  - `from = period.started_at`
- `periodSummaryProvider.family<({double income, double expense}), String periodId>` —
  `watchSummary` di rentang periode itu. (buat list "Periode N: +X / -Y")
- Semua provider laporan existing (`insightsSummaryProvider`, `categoryBreakdownProvider`,
  `cashflowTrendProvider`, `budgetsWithProgressProvider`) udah baca `reportRangeProvider` →
  otomatis ngikut periode terpilih. `budgetsWithProgressProvider` sekarang pakai
  `activePeriodProvider` — ganti ke periode terpilih (buat lihat budget periode lama).

### Mobile — UI (`insights_screen.dart`)
- Di atas, **dropdown / segmented selector periode**: "Aktif (sejak d MMM)" + tiap periode
  lama ("d MMM – d MMM yyyy"). Pilih → `selectedPeriodProvider`.
- Section baru **"Ringkasan per Periode"** (atau taro di paling atas): list semua periode +
  income/expense masing-masing (dari `periodSummaryProvider`). Tap row → set selected +
  scroll ke detail.
- Sisanya (budget list, cashflow, breakdown) otomatis re-scope ke periode terpilih.
- Kalau periode lama dipilih: budget section jadi **read-only** (sembunyiin tombol "+"
  set budget & swipe-delete) — histori jangan diubah.

### Backend
- `/reports/*` endpoint: sekarang nerima `from`/`to` query? Cek `reports.controller`. Kalau
  udah → mobile ga butuh perubahan BE (mobile ga pake `/reports` lagi sejak plan 029).
  **Ga ada perubahan BE** — semua di mobile dari Drift.

### Verifikasi Item 2
1. `flutter analyze` clean, test pass.
2. Bikin 3 periode (mulai periode baru 3x, isi transaksi di tiap rentang).
3. Insights: selector nampilin 3 periode. "Ringkasan per Periode" nunjukin income/expense
   bener per periode (cocok sama transaksi di rentang tanggalnya).
4. Pilih periode lama → cashflow + breakdown + budget re-scope ke periode itu; budget
   read-only (ga bisa tambah/hapus).
5. Pilih "Aktif" → balik ke `to = hari ini`, budget bisa diedit lagi.
6. Transaksi di tanggal jeda antar-periode (kalau ada) → ga muncul di periode mana pun
   (dokumentasikan; bukan bug).

---

## Out of Scope
- Kolom FK `transactions.period_id` (nyambungin transaksi ke periode secara eksplisit) —
  match by tanggal cukup, nambah kolom = migrasi + maintain konsistensi pas edit tanggal.
- Edit `started_at` periode yang udah jalan.
- Hapus periode.
- Nutup periode tanpa buka yang baru (sekarang `startNewPeriod` selalu pasangan).

## Urutan
Item 1 (rename) dulu — commit sendiri. Item 2 (laporan per periode) di atasnya.

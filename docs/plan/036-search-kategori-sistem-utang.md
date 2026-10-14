# 036 — Search transaksi, kategori sistem, drill-down, fix kategori terhapus, fitur utang

Status: Draft — belum dikerjakan
Sumber: user. 5 item + 1 keputusan infra penting.

---

## Keputusan 0 — Migration strategy mobile: berhenti nuke-on-upgrade

**Konteks**: data Postgres baru aja ke-wipe total (container+volume ke-delete) dan
dipulihin dari HP (satu-satunya sumber data yang selamat). Item 5 (utang) nambah
tabel baru + kolom baru di `transactions` — butuh `schemaVersion` naik.

**Sekarang** `app_database.dart` `onUpgrade`: DROP semua tabel + `createAll()` (reset
total, dipakai sejak awal dev karena data masih coba-coba). Kalau dipakai lagi
sekarang, **data real yang baru dipulihin ke-hapus lagi** dari HP (bisa direstore
ulang dari Postgres via sync pull, tapi berisiko & annoying, dan Postgres sendiri
baru kebuktian bisa hilang).

**Keputusan**: ganti ke migration **incremental** (Drift `MigrationStrategy.onUpgrade`
pakai `m.addColumn` / `m.createTable` per versi, bukan drop). `schemaVersion` 3 → 4,
step migrasinya nambahin tabel `debts` + kolom `transactions.debt_id` doang (aman,
additive, data existing gak kesentuh). Strategi nuke yang lama DIBUANG mulai sekarang
— setiap schema change selanjutnya pakai additive migration.

---

## Item 1 — Search transaksi (nama/catatan + kategori)

### Mobile aja (filter di layer Dart atas stream yang udah ada)
- `transactions_list_screen.dart`: `TextField` search di atas `_AccountBalanceStrip`
  (atau gabung jadi 1 baris). State: `txnSearchQueryProvider` (`StateProvider.autoDispose<String>`).
- Filter: transaksi match kalau query (case-insensitive, trim) ada di substring
  `note` **atau** nama kategori (`categoriesByIdProvider[categoryId]?.name`) **atau**
  nama akun. Kosong = tampil semua (gak ada filter).
- Terapin di level `_GroupedList` (filter sebelum grouping by tanggal), biar query
  ga perlu nyentuh DAO/SQL (dataset personal-scale, filter di Dart cukup ringan).
- Icon search bisa collapse/expand (tap icon di AppBar → muncul TextField) biar gak
  makan tempat terus — atau langsung tampil kalau user udah biasa pakai. **Pilih:
  langsung tampil di bawah AppBar** (konsisten sama `_AccountBalanceStrip`, gak perlu
  animasi expand).

---

## Item 2 — Kategori sistem "Penyesuaian" (bukan lagi tanpa-kategori)

### Backend
- Gak ada migrasi skema baru (categories table udah ada, cuma nambah 1 row data per
  user). Tapi butuh cara bikin row-nya — paling simpel: **mobile** yang bikin pas
  pertama butuh (lazy-create), sync dorong ke server kaya kategori biasa. Gak perlu
  endpoint/migration backend khusus.

### Mobile
- `categories.dart` (table): tambah `BoolColumn get isSystem => boolean().named('is_system').withDefault(const Constant(false))()`.
  (Schema bump — masuk ke migration v4 yang sama kaya Item 5, additive:
  `m.addColumn(categories, categories.isSystem)`.)
- `sync.constants.ts` (backend) + `backend/migrations/`: kolom `is_system` ditambah ke
  `categories` (migration ALTER baru — tabel `categories` udah ada data, gak di-fold
  ke CREATE). Default `false`.
- `CategoriesRepository`: `ensureSystemCategory(userId, type)` — cari kategori
  `is_system=true & type=type & name='Penyesuaian'`; kalau belum ada, bikin (upsert
  lokal, `pendingSync=true`). Dipanggil dari `TransactionsRepository.createUncategorized`
  sebelum insert, pakai `categoryId` hasilnya (ganti `categoryId: const Value(null)`).
- `categoriesListProvider` (buat picker form transaksi/recurring/budget): filter
  `isSystem == false` — kategori sistem gak muncul buat dipilih manual.
  `categoriesByIdProvider` / breakdown / histori: tetep include (gak difilter) biar
  nama "Penyesuaian" muncul normal di situ.
- **Data lama**: transaksi existing yang `category_id IS NULL` (udah ada histori
  "Penyesuaian saldo" / "Biaya transfer" dari sebelum fitur ini) — backfill jadi
  pakai kategori sistem yang baru dibuat. Script satu-kali di mobile (jalan sekali
  pas migration v4, atau tombol manual di Settings "Rapihin data lama"). **Pilih:**
  jalanin otomatis di `MigrationStrategy` step v4 — `UPDATE transactions SET
  category_id = <id kategori sistem per type> WHERE category_id IS NULL AND type IN
  ('Income','Expense')`. Kategori sistemnya dibuat duluan di step migrasi yang sama.

---

## Item 3 — Drill-down breakdown kategori → list transaksi

### Mobile
- `_CategoryBreakdownChart` (insights_screen.dart): tiap row dibungkus `InkWell`,
  `onTap` → push ke `TransactionsListScreen` varian baru dengan filter
  `categoryId` + rentang periode yang lagi dilihat (`reportRangeProvider`).
- `transactions_list_screen.dart` butuh terima optional `categoryId` + `from`/`to`
  filter (extend `TransactionFilter`, udah ada `categoryId`/`from`/`to` — tinggal
  disambungin dari route baru, bukan cuma `txnAccountFilterProvider`).
- Route baru `/transactions/by-category/:categoryId?from=...&to=...` di `router.dart`,
  atau simpel: push `MaterialPageRoute` langsung (gak lewat go_router path) bawa
  argument — konsisten sama cara form screen lain di-push (`Navigator.of(context).push`).
  **Pilih yang ini** — gak nambah route string, cukup widget baru
  `CategoryTransactionsScreen({categoryId, from, to, title})`.

---

## Item 4 — Fix: kategori terhapus tampil "?" di breakdown/histori

**Bug**: `_CategoryBreakdownChart` & `_BudgetList` (insights_screen.dart) pakai
`categoriesListProvider(null)` buat lookup nama — provider itu `watchAll(...)` yang
filter `deletedAt.isNull()`. Kategori yang udah di-soft-delete gak ketemu →
`firstOrNull?.name ?? '?'`.

### Mobile — fix
- Ganti pemakaian di `_CategoryBreakdownChart.nameOf` & `_BudgetList` (categoryName)
  dari `categoriesListProvider(null)` → `categoriesByIdProvider` (udah ada, include
  soft-deleted, dipake transactions_list_screen buat kasus sama). Nama kategori lama
  tetep muncul walau kategorinya udah dihapus.

---

## Item 5 — Fitur Utang/Piutang (dua arah)

Mirror pola **Goals** (plan 029) persis — tabel baru + tag opsional di `transactions`,
progress dihitung on-the-fly dari SUM transaksi yang di-tag, bukan kolom tersimpan.

### Konsep
- 1 record `debts` = 1 utang/piutang. `direction`: `'Utang'` (saya berutang → saya
  yang bayar/cicil) atau `'Piutang'` (orang berutang ke saya → saya yang nagih/terima).
- `counterparty` (nama orang/pihak), `amount` (pokok), `due_date` opsional, `note`
  opsional.
- Pelunasan = transaksi normal (Expense buat Utang, Income buat Piutang) yang user
  tag ke `debt_id` saat input — **gak otomatis bikin transaksi pas create record**,
  sama kaya goals (user yang nyatet pelunasan sendiri via form transaksi biasa).
- Progress = `SUM(amount)` transaksi yang `debt_id = ini` (gak peduli Income/Expense,
  trust user kaya goal_id). **Lunas** kalau progress ≥ amount.

### Backend
- Migration baru: `CREATE TABLE debts (id, user_id FK, direction CHECK IN ('Utang','Piutang'),
  counterparty TEXT NOT NULL, amount NUMERIC(18,2) CHECK > 0, due_date DATE NULL,
  note TEXT NULL, created_at, updated_at, deleted_at)`. Index `user_id`.
- Migration: `ALTER TABLE transactions ADD COLUMN debt_id UUID REFERENCES debts(id);`
  + index. (Kolom nempel di akhir — transactions udah ada data, gak di-reorder/recreate.)
- `debts.repository.ts` + `debts.controller.ts` + `debts.module.ts` — CRUD standar,
  mirror `goals` module exact (create/list/update/delete, soft delete).
- `sync.constants.ts`: tabel baru `debts` (kolom id,user_id,direction,counterparty,
  amount,due_date,note,created_at,updated_at,deleted_at) + `transactions` kolom
  tambah `debt_id`.

### Mobile
- `tables/debts.dart` (baru) — mirror `goals.dart`. `transactions.dart` tambah
  `TextColumn get debtId => text().named('debt_id').nullable()()`.
- `schemaVersion` → 4, `MigrationStrategy.onUpgrade` step **additive** (lihat
  Keputusan 0): `m.createTable(debts)`, `m.addColumn(transactions, transactions.debtId)`,
  `m.addColumn(categories, categories.isSystem)` + backfill Item 2.
- `DebtsDao` + `DebtsRepository` — mirror `GoalsDao`/`GoalsRepository` +
  `watchDebtTotal(debtId)` (mirror `watchGoalTotal`) di `TransactionsDao`.
- `sync_serializers.dart`: `debtToJson`/`debtFromJson`, `transactionToJson` tambah
  `debt_id`.
- `features/debts/` (baru): `debts_providers.dart`, `debts_list_screen.dart` (list +
  progress bar + lunas badge, mirror `goals_list_screen.dart`), `debt_form_screen.dart`
  (mirror `goal_form_screen.dart`: direction ChoiceChip Utang/Piutang, counterparty
  TextField, amount CalcAmountField, due_date opsional).
- `transaction_form_screen.dart`: dropdown "Tag ke utang/piutang (opsional)" — mirror
  dropdown goal yang udah ada, muncul kalau ada debt yang belum lunas.
- Nav: entry baru di `more_screen.dart` ("Utang & Piutang") ke `DebtsListScreen` —
  gak nambah tab bottom-nav (udah 4, penuh).

---

## Urutan eksekusi
1. **Keputusan 0** dulu — ganti migration strategy ke additive, schemaVersion 3→4.
2. Item 4 (fix kategori terhapus) — kecil, berdiri sendiri, gak butuh schema.
3. Item 2 (kategori sistem Penyesuaian) — butuh migration v4 (is_system + backfill).
4. Item 5 (utang) — migration v4 yang sama (debts table + debt_id), fitur paling besar.
5. Item 3 (drill-down breakdown) — UI doang, setelah data kategori rapi.
6. Item 1 (search) — UI doang, independen, bisa kapan aja.
Tiap kelompok = commit sendiri. Backend migration (debts + is_system + debt_id)
dijalanin manual di DB yang baru dipulihin — **cek dulu row count sebelum & sesudah**
tiap migrate, jangan sampai keulang insiden kemarin.

## Verifikasi
1. `flutter analyze` + `flutter test` + backend `build`+`eslint` clean tiap commit.
2. **Migration v4**: install APK baru di atas yang lama → data existing (akun,
   transaksi, dst) **masih ada** (bukan ke-reset). Kategori "Penyesuaian" otomatis
   muncul, transaksi penyesuaian lama ke-retag ke situ.
3. **Search**: ketik nama kategori → transaksi kategori itu doang muncul. Ketik
   sebagian catatan → match. Kosongin → balik semua.
4. **Breakdown**: kategori yang udah dihapus tapi ada histori → nama asli muncul
   (bukan "?"). Tap row kategori → masuk list transaksi kategori itu di periode ini.
5. **Utang**: bikin "Utang" ke "Budi" 500rb → catat transaksi Expense 200rb tag ke
   situ → progress 200rb/500rb, belum lunas. Tambah 300rb lagi → lunas.
6. Backend: `npm run migrate:up` clean di DB yang baru dipulihin, row count tabel lama
   (`accounts=10, transactions=157`, dst) **gak berubah** sebelum/sesudah migrate.

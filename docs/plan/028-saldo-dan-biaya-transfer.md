# 028 — Saldo Akun & Biaya Transfer

Status: Draft — belum dikerjakan
Sumber: permintaan user. 2 item:
- **Item 1** — rekonsiliasi saldo akun (saldo app ≠ saldo asli karena ada transaksi lupa dicatat).
- **Item 2** — biaya admin transfer (tiap transfer antar bank kadang kena biaya, mis. Rp 2.000).

Pendekatan dua-duanya sama: **generate transaksi turunan** (bukan nambah kolom / geser
baseline), konsisten sama filosofi "Transfer = 1 row" + on-the-fly balance di SCHEMA.md.

---

## Item 1 — Rekonsiliasi Saldo Akun (Transaksi Penyesuaian)

Sumber: user sering lupa catat pengeluaran/pemasukan di app, jadi saldo app ≠ saldo asli
rekening. Mau samain dari app **tanpa kehilangan jejak** kalau memang uangnya beneran gerak.

### Masalah
Setelah plan 027, form **Edit Akun** cuma bisa ubah nama. Kalau saldo berjalan melenceng dari
saldo asli (biasanya karena ada transaksi lupa dicatat), gak ada cara koreksi.

Saldo berjalan = `initial_balance + SUM(transaksi)` (on-the-fly, SCHEMA.md).

### Keputusan — kenapa transaksi penyesuaian, bukan geser `initial_balance`
User bilang case-nya = **lupa catat transaksi nyata**. Berarti uangnya beneran keluar/masuk,
cuma gak ke-log. Kalau digeser lewat `initial_balance`:
- Riwayat transaksi gak nunjukin ada yang berubah.
- Saldo historis di semua titik waktu ikut geser (padahal selisihnya kejadian di 1 titik).
- Laporan cashflow gak kena → padahal uangnya beneran gerak.

Jadi: selisihnya dicatat sebagai **1 transaksi penyesuaian** (Income kalau saldo asli lebih
besar, Expense kalau lebih kecil). `initial_balance` gak disentuh.

### Cara kerja
- Di form **Edit Akun**, tambah field **"Saldo saat ini"** (`MoneyField`), prefilled dengan
  saldo berjalan sekarang (snapshot sekali).
- User ketik saldo yang bener → on save:
  ```
  delta = input − saldo_berjalan_sekarang
  delta > 0  → transaksi Income  sebesar delta
  delta < 0  → transaksi Expense sebesar |delta|
  delta == 0 → gak ada transaksi (cukup update nama kalau berubah)
  ```
- Transaksi penyesuaian: `account_id` = akun ini, `category_id` = NULL, `type` = Income/Expense,
  `amount` = |delta|, `occurred_at` = hari ini, `note` = `"Penyesuaian saldo"`.
- `recurring_rule_id` / `goal_id` NULL.

### Konsekuensi (diterima)
- Muncul di **list Transactions** sebagai row "Penyesuaian saldo" (bisa di-edit/hapus manual
  kayak transaksi biasa) — ini justru yang diminta (ada jejak).
- **Category breakdown** (Insights): drop otomatis — `reports.repository` INNER JOIN
  `categories`, transaksi `category_id=NULL` gak keitung. Wajar, penyesuaian bukan kategori.
- **Cashflow trend**: keitung sebagai in/out. Wajar — uangnya beneran gerak.
- `occurred_at` = hari ini (bukan tanggal transaksi asli yang kelupaan, karena gak diketahui).
  `ponytail:` kalau perlu, tambah date picker di dialog nanti. Sekarang: hari ini.

### Scope — Backend (NestJS + Postgres): no migration, no DTO baru
- **Gak ada perubahan.** Transaksi penyesuaian di-generate di mobile, lalu sync lewat jalur
  column-driven (`sync.constants` + `sync.repository`) yang **gak lewat** `CreateTransactionDto`
  (jadi `category_id=NULL` buat Income/Expense diterима — validasi `@ValidateIf` DTO cuma
  berlaku di `POST /transactions` REST, bukan sync).
- Verifikasi: `reports.repository` `categoryBreakdown` pakai `JOIN categories` (bukan LEFT) —
  konfirmasi transaksi null-category emang ke-exclude, gak bikin error.

### Mobile (Flutter + Drift) — no schema change
- `mobile/lib/data/repository/transactions_repository.dart`:
  - method baru `createAdjustment({ userId, accountId, type, amount, note })` — insert langsung
    ke DAO, `categoryId: const Value(null)`, `occurredAt = today`, `pendingSync` default true.
    **Skip `_validate`** (akun dijamin ada — dari form; kategori sengaja null).
- `mobile/lib/data/repository/accounts_repository.dart`:
  - `watchBalance` udah ada (`accountBalanceProvider`) — dipakai buat snapshot.
- `mobile/lib/features/accounts/account_form_screen.dart`:
  - edit mode: `MoneyField` label "Saldo saat ini".
  - prefill: `ref.read(accountBalanceProvider(account).future)` sekali di `initState`
    (atau `FutureBuilder`), set controller pas resolve, guard biar gak nimpa ketikan user.
  - on submit (edit):
    ```dart
    final entered = moneyValue(_balanceController.text).toDouble();
    final delta = entered - _snapshotBalance;   // _snapshotBalance = saldo pas form kebuka
    if (delta.abs() >= 0.5) {                    // toleransi pembulatan
      await txnRepo.createAdjustment(
        userId: userId, accountId: id,
        type: delta > 0 ? 'Income' : 'Expense',
        amount: delta.abs(),
        note: 'Penyesuaian saldo',
      );
    }
    await accRepo.update(id: id, name: _nameController.text);   // nama tetap bisa berubah
    ```
  - `accountsRepositoryProvider` + `transactionsRepositoryProvider` dua-duanya di-`ref.read`.
- Field "Saldo saat ini" **cuma di edit mode**. Create tetap "Saldo awal" → `initial_balance`
  (behavior plan 027, gak berubah).
- Saldo berjalan reaktif otomatis ke-recompute abis transaksi penyesuaian masuk — list akun,
  Home, list Transactions langsung update.

### Verifikasi
1. `flutter analyze` clean. Backend gak berubah (tetap `build` + `eslint` clean).
2. Akun ada beberapa transaksi. Edit → "Saldo saat ini" keisi = saldo di list.
3. Naikin angkanya (mis. +50.000) → simpan → muncul transaksi **Income "Penyesuaian saldo"
   Rp 50.000** di list Transactions hari ini; saldo akun & total Home naik 50.000.
4. Turunin angka → transaksi **Expense "Penyesuaian saldo"**.
5. Ketik angka sama persis → simpan → gak ada transaksi baru.
6. Edit cuma nama → gak ada transaksi baru, nama berubah.
7. Transaksi penyesuaian bisa di-swipe-hapus / di-tap-edit kayak transaksi biasa.
8. Sync (More → Sync) → transaksi penyesuaian masuk Postgres; `GET /accounts` field `balance`
   match; `GET /reports/category-breakdown` gak error & gak nampilin penyesuaian.
9. Insights → cashflow trend keitung penyesuaian; breakdown kategori enggak.

### Out of Scope (Item 1)
- Date picker buat tanggal penyesuaian (default hari ini).
- Kategori khusus "Penyesuaian" (pakai `category_id=NULL`).
- Geser `initial_balance` langsung (ditolak — hilang jejak).
- Rekonsiliasi otomatis / import mutasi bank (backlog PRD).
- Tipe transaksi baru `Adjustment` (pakai Income/Expense biasa + note, cukup).

---

## Item 2 — Biaya Admin Transfer

Sumber: user — tiap transfer antar bank kadang kena biaya admin (mis. Rp 2.000). Sekarang
form Transfer cuma: akun asal, akun tujuan, nominal. Biaya admin gak ke-catat, jadi saldo
akun asal jadi meleset tiap transfer.

### Model sekarang (SCHEMA.md)
Transfer = **1 row**: `account_id` (asal), `transfer_to_account_id` (tujuan), `amount`,
`type='Transfer'`, `category_id=NULL`. Balance: asal `−amount`, tujuan `+amount`.

### Keputusan
Biaya admin = **transaksi Expense turunan** yang ke-generate barengan transfer:
- `account_id` = akun asal, `type='Expense'`, `amount` = biaya, `category_id=NULL`,
  `occurred_at` = tanggal transfer, `note='Biaya transfer'`.
- Transfer row-nya sendiri **gak berubah** (tetap 1 row, `amount` = nominal transfer murni).
- Efek saldo: akun asal `−(amount + biaya)`, akun tujuan `+amount`. Bener.

Kenapa row terpisah, bukan kolom `fee` di transactions:
- Gak perlu migration + gak perlu ubah 4 tempat kalkulasi balance (BE `getBalance`,
  mobile `watchAccountBalance` + `watchNetDeltaForAccounts`) + logika reports.
- Expense null-category udah otomatis bener di semua report: masuk `getSummary` /
  `getCashflowTrend` (SUM FILTER type='Expense'), ke-skip `getCategoryBreakdown` (INNER JOIN
  categories). Uda diverifikasi baca `backend/src/reports/reports.repository.ts`.
- Konsisten sama Item 1 (transaksi turunan).

Trade-off diterima:
- 2 row di histori buat 1 aksi transfer. Biaya transfer bisa di-hapus/edit sendiri.
- Edit nominal transfer nanti **gak** otomatis update baris biaya (stale). Solo-user, jarang —
  `ponytail:` kalau ganggu, link via kolom nanti.

### Scope — Mobile only, no backend, no schema
- `mobile/lib/data/repository/transactions_repository.dart`:
  - method `createTransferFee({ userId, accountId, amount, occurredAt })` — insert Expense
    langsung ke DAO, `categoryId: const Value(null)`, `note: 'Biaya transfer'`, skip
    `_validate` (kategori sengaja null). Atau generalisir bareng `createAdjustment` Item 1
    jadi 1 helper `_createUncategorized({type, amount, occurredAt, note})`.
- `mobile/lib/features/transactions/transaction_form_screen.dart`:
  - pas `_type == 'Transfer'`: tampilkan field opsional **"Biaya admin"** (`MoneyField`,
    boleh kosong/0) di bawah "Akun tujuan".
  - submit transfer: setelah create transfer row, kalau biaya > 0 → `createTransferFee(...)`
    dengan `occurredAt` = `_occurredAt` transfer.
  - edit transfer (`_isEdit`): field biaya **disembunyiin** (edit transfer emang udah
    dibatasi sekarang — `onSelectionChanged` null pas edit). Biaya lama gak diutak-atik.
- Saldo & list reaktif — langsung kebaca.

### Verifikasi (Item 2)
1. `flutter analyze` clean. Backend gak berubah.
2. Buat Transfer Rp 100.000 dari A ke B, isi Biaya admin Rp 2.000 → submit:
   - list Transactions: 1 row Transfer Rp 100.000 + 1 row Expense "Biaya transfer" Rp 2.000.
   - saldo A turun 102.000, saldo B naik 100.000.
3. Transfer tanpa isi biaya (kosong / 0) → cuma 1 row Transfer, gak ada row biaya.
4. Row "Biaya transfer" bisa di-hapus/edit sendiri.
5. Sync → dua row masuk Postgres; `GET /accounts` balance A & B match.
6. Insights → biaya transfer keitung di total Expense & cashflow trend; gak muncul di
   breakdown kategori.

### Out of Scope (Item 2)
- Kolom `fee` di `transactions`.
- Biaya nempel/ke-link ke row transfer (auto-hapus/auto-update bareng).
- Biaya di sisi akun tujuan (jarang; kalau ada, user catat manual).
- Preset nominal biaya per akun.

---

## Next
Belum ada.

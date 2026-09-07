# 035 — Akun ordering, kalkulator input, tampilan transaksi

Status: Draft — belum dikerjakan
Sumber: user (testing di device). 6 item.

---

## Item 1 — Ordering akun (drag)
Mirror kategori (plan 027 Item 4).

### Backend
- Migrasi: `ALTER TABLE accounts ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;`
  + backfill `row_number() OVER (PARTITION BY user_id ORDER BY created_at) - 1`.
- `accounts.repository.ts`: interface + `findAllByUser` → `ORDER BY sort_order ASC, created_at ASC`.
  `update` terima `sortOrder?` opsional.
- `sync.constants.ts`: tabel `accounts` kolom tambah `'sort_order'`.

### Mobile
- `tables/accounts.dart`: `sortOrder => integer().named('sort_order').withDefault(const Constant(0))()`.
- `schemaVersion` naik → `onUpgrade` auto-reset (dev phase).
- `AccountsDao`: `watchAll` orderBy `[sortOrder, createdAt]`, method `reorder(orderedIds, now)`.
- `accounts_repository.dart`: `reorder(ids)` passthrough.
- `sync_serializers.dart`: `accountToJson`/`FromJson` + `sort_order`.
- `accounts_list_screen.dart`: `ReorderableListView.builder` + `_pending` optimistik (pola
  kategori — biar ga mental-balik). Drag handle di trailing.
- `accounts_providers.dart`: `accountsListProvider` udah ada.

---

## Item 2 — Input angka pakai kalkulator in-app (bukan keyboard OS)
Semua input nominal: numpad custom + operasi `+ − × ÷`. Pas input transaksi bisa
`3 × 15000`, `2000 + 500`, dll.

### `shared/calc_pad.dart` (baru)
- Widget `CalcPad` — grid tombol: `7 8 9 ÷` / `4 5 6 ×` / `1 2 3 −` / `000 0 ⌫ +` + baris
  `=` (atau `=` gede di kanan). Callback `onKey(String)`.
- Fungsi `evalExpression(String expr) -> double?` — shunting-yard, presedensi `× ÷` >
  `+ −`, operand non-negatif integer (IDR bulat). Invalid → null. **Test wajib.**
- State di parent: `String _expr`. Tampil expr + hasil live (`= Rp 47.000`).

### `shared/calc_amount_field.dart` (baru)
- Pengganti `MoneyField` di form non-transaksi (akun saldo, recurring nominal, goal target,
  budget limit). `TextFormField` read-only + `onTap` buka **bottom sheet** berisi `CalcPad`
  + preview. Confirm → set nilai (hasil eval, dibulatkan). Tampil ke-format Rupiah.
- `moneyValue` / `moneyText` helper tetap dipakai buat format.

### `transaction_form_screen.dart`
- `_amount` (string digit) → `_expr` (string expression).
- Ganti `NumPad` → `CalcPad`. Tampilan atas: `_expr` + `= formatRupiah(hasil)`.
- Submit: `amount = evalExpression(_expr) ?? 0`, validasi `> 0`.
- `NumPad` lama: dihapus kalau ga kepake lagi (cek).

### Out of scope item 2
- Kurung `( )`, desimal, persen. Riwayat kalkulasi.

---

## Item 3 — Transaksi: ordering `updated_at DESC` + waktu di kanan
### DAO
- `watchAll` + `watchRecent`: `orderBy` → `OrderingTerm.desc(t.updatedAt)` (dari
  `occurred_at`).
- `_GroupedList` (transactions_list_screen): grouping header by **`updated_at` date**
  (Hari ini / Kemarin / d MMM yyyy) — biar konsisten sama urutan.

### Tile
- Trailing: kolom — nominal (atas) + **jam** `HH:mm` dari `updated_at` (bawah, kecil, abu).
- (occurred_at tetap date-only dari plan 033; waktu yang ditampilin = `updated_at`.)

---

## Item 4 — Row transaksi tanpa note → tampil nama kategori
Sekarang: `note` ?? `type` ("Income"/"Expense"/"Transfer").
Mau: `note` ?? `nama kategori` ("Parkir") ?? `type` (Transfer ga punya kategori → "Transfer").

- Re-add `categoriesByIdProvider` di `categories_providers.dart` — `Map<String, Category>`
  dari `watchAllIncludingDeleted` (biar kategori kehapus tetap kebaca di histori).
- `_TransactionTile` + Home recent tile: title =
  `note?.isNotEmpty == true ? note : (catMap[categoryId]?.name ?? type)`.

---

## Item 5 — Ikon tipe transaksi diwarnai
`_TransactionTile` + Home recent leading `Icon`:
- Income → `Icons.arrow_downward`, warna `semantic.income` (hijau)
- Expense → `Icons.arrow_upward`, warna `semantic.expense` (merah)
- Transfer → `Icons.swap_horiz`, warna `colorScheme.primary` (oranye Karasuno)
- Bungkus `CircleAvatar` tipis (bg warna alpha 0.15) biar makin kebaca — opsional, default
  ikon berwarna aja.

---

## Item 6 — Home "transaksi terakhir" → semua transaksi HARI INI
Sekarang: `watchRecent(limit: 5)`.
Mau: semua transaksi `occurred_at` = hari ini (atau `updated_at` = hari ini? — pakai
`occurred_at` hari ini, sesuai "transaksi hari ini"). Urut `updated_at DESC`.

- Provider baru `todayTransactionsProvider` → `watchAll(userId, from: todayStart,
  to: todayEnd)`.
- `home_screen`: ganti `recentTransactionsForHomeProvider` → `todayTransactionsProvider`.
  Judul section "Transaksi hari ini". Empty state "Belum ada transaksi hari ini".
- "Lihat semua" tetap → `/transactions` full-screen.
- `watchRecent` + `recentTransactionsProvider` + `recentTransactionsForHomeProvider`:
  cek masih kepake di tempat lain; kalau enggak, hapus.

---

## Verifikasi
1. `flutter analyze` + `build_runner` + test clean. Backend `migrate:up`/`down` + `build` +
   `eslint` clean.
2. **Akun**: drag akun → urutan persist (kill app), ga mental-balik. Sync → `sort_order`
   ke Postgres.
3. **Kalkulator**: transaksi `3 × 15000` → `= Rp 45.000` → submit → transaksi Rp 45.000.
   `2000 + 3 × 500` → `Rp 3.500` (presedensi). Form akun/goal/budget/recurring → tap field
   → sheet kalkulator → confirm → nilai keisi.
4. **Ordering**: edit transaksi lama → dia lompat ke atas list (updated_at). Jam di kanan.
5. **Title**: transaksi "Parkir" tanpa note → row nampilin "Parkir". Ada note → nampilin note.
6. **Ikon**: Income ijo, Expense merah, Transfer oranye — di list & Home.
7. **Home**: nampilin semua transaksi hari ini (bukan cuma 5), urut updated_at desc.

## Urutan eksekusi
1. Item 1 (akun ordering) — schema, sendiri.
2. Item 3+4+5+6 (tampilan transaksi + provider) — barengan, saling sentuh tile.
3. Item 2 (kalkulator) — paling gede, sendiri.
Tiap kelompok = commit sendiri.

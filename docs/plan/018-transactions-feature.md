# 018 — Transactions Feature

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: SCHEMA.md (`transactions`), DESIGN.md §6 (Transactions screen, Add Transaction screen)

## Context
Fitur inti — layout & interaksi udah didetailin di `DESIGN.md` §6 (segmented toggle, numpad custom, swipe delete, dll). Balance akun (plan 016) otomatis reaktif ke perubahan di sini krn sama-sama baca dari local DB yang sama.

## Scope
1. `lib/data/repository/transactions_repository.dart` — wrap `TransactionsDao`, dirty-tracking, plus query balance on-the-fly per akun (mirror logic SQL backend plan 003, versi Drift/SQL lokal)
2. `lib/features/transactions/transactions_list_screen.dart` — list grouped by tanggal (Hari ini/Kemarin/dst), filter collapsed (akun/kategori/tanggal), swipe-to-delete (`Dismissible`), tap → edit
3. `lib/features/transactions/transaction_form_screen.dart` — halaman penuh (dari FAB, plan 014 route `/transactions/add`, juga dipakai buat edit lewat `/transactions/:id/edit`):
   - Segmented toggle Expense/Income/Transfer (default Expense)
   - Numpad custom buat input nominal (gede, di atas)
   - Akun (chip selector), kategori (grid ikon, kategori terakhir dipake muncul duluan — sesuai DESIGN.md prinsip UX), tanggal (default hari ini), catatan (collapsed/optional)
   - Validasi client-side mirror CHECK constraint backend (transfer wajib akun tujuan & beda dari akun asal, non-transfer wajib kategori)
4. `lib/features/transactions/transaction_providers.dart` — Riverpod provider list + filter state
5. Wiring FAB (plan 014) ke form ini

## Out of Scope
- Sync ke backend (plan 020)
- Home dashboard (plan 019, tapi consume repository yang sama)

## Verification
1. Tambah transaksi expense → langsung muncul di list, saldo akun (plan 016) ke-update reaktif
2. Tambah transfer antar akun → 1 entry transaksi, 2 akun ke-update
3. Transfer ke akun sendiri → ditolak di form (client-side), gak sempet nembus ke DB
4. Swipe kiri transaksi → delete (soft delete), saldo balik kayak sebelumnya
5. Data transaksi persisted abis app di-kill
6. `flutter analyze` clean

## Next
Plan 019 — Home/Dashboard screen.

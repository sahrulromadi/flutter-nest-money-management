# 032 — Home tap-to-edit, edit akun di transaksi, nav Akun

Status: Draft — belum dikerjakan
Sumber: user (dari testing di device).

## Item 1 — Home: tap transaksi → edit
`home_screen.dart` list "5 transaksi terakhir" — row `ListTile` belum ada `onTap`.
Tambah `onTap: () => context.push('/transactions/${t.id}/edit')`. Route udah ada.

## Item 2 — Edit transaksi: akun bisa diganti
Sekarang di form edit, chip **akun** & **akun tujuan** di-disable (`onSelected: _isEdit ? null`).
Kategori udah bisa. Bikin akun juga bisa (tipe transaksi tetap locked di edit — ganti
Income↔Transfer bikin ribet).

- `transaction_form_screen.dart`:
  - chip akun: `onSelected: (_) => setState(() => _accountId = a.id)` (buang guard `_isEdit`).
  - chip akun tujuan (Transfer): idem.
  - `_submit` cabang edit: kirim `accountId: _accountId`, `transferToAccountId:
    _type == 'Transfer' ? _transferToAccountId : null`.
- `transactions_repository.dart` `update()` — tambah param `accountId`, `transferToAccountId`.
  Set di `TransactionsCompanion` (pakai `Value` kalau non-null).
- `_validate` ga jalan di update (cuma create) — chip cuma nampilin akun valid, cukup.

## Item 3 — Bottom nav: buang tab Transactions, ganti Akun
User lebih sering buka list akun; transaksi cukup lewat "Lihat semua" di Home.

Nav lama: `Home — Transactions — [+] — Insights — More`
Nav baru: `Home — Akun — [+] — Insights — More`

- `app_shell.dart`: `_labels` → `['Home', 'Akun', 'Insights', 'More']`,
  `_icons` → `[home_outlined, account_balance_wallet_outlined, insights_outlined, more_horiz]`.
- `router.dart`:
  - branch ke-2: `path: '/transactions'` → `path: '/accounts'`,
    `TransactionsListScreen()` → `AccountsListScreen()`.
  - tambah top-level `GoRoute(path: '/transactions', builder: TransactionsListScreen())`
    **di luar** shell (full-screen, ada tombol back otomatis).
- `home_screen.dart:43`: `context.go('/transactions')` → `context.push('/transactions')`.
- `more_screen.dart`: hapus `ListTile` "Akun" (udah jadi tab).
- `AccountsListScreen` udah punya Scaffold+AppBar+FAB sendiri — jalan sebagai tab di dalam
  `AppShell`. FAB "tambah akun" (endFloat) ga nabrak FAB tengah shell (centerDocked).
- `DESIGN.md` §6 — update struktur navigasi.

## Verifikasi
1. `flutter analyze` clean.
2. Home: tap row transaksi → buka form edit transaksi itu.
3. Edit transaksi: ganti akun → simpan → saldo akun lama & baru ke-update; transaksi
   pindah akun. Transfer: ganti akun asal/tujuan jalan.
4. Bottom nav: tab ke-2 = "Akun" (ikon dompet) → list akun. Ga ada tab Transactions.
5. Home → "Lihat semua" → buka list transaksi full-screen + tombol back.
6. More → ga ada entri "Akun" lagi.
7. FAB tengah "+" tetap di semua tab; di tab Akun ada 2 FAB (tengah = transaksi,
   kanan-bawah = tambah akun) — ok.

## Out of Scope
- Ganti tipe transaksi (Income/Expense/Transfer) di edit.
- Pindah "tambah akun" dari FAB ke AppBar action.

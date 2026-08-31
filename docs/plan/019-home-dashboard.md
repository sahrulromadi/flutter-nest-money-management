# 019 — Home / Dashboard Screen

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: DESIGN.md §6 (layout Home)

## Context
Layar pertama yang keliatan tiap buka app. Agregasi dari data yang udah ada (accounts + transactions, plan 016 & 018) — gak ada data/tabel baru.

## Scope
1. `lib/features/home/home_screen.dart`:
   - Total saldo (SUM semua akun) — angka gede paling menonjol
   - Snapshot periode ini: total income vs expense (default: bulan berjalan, krn budget period custom baru masuk plan 021) — 2 angka bersebelahan, warna sesuai semantic color (DESIGN.md §4)
   - 5 transaksi terakhir (reuse widget row dari plan 018) + link "Lihat semua" → tab Transactions
   - Empty state kalau belum ada transaksi sama sekali ("Belum ada transaksi, yuk catat yang pertama" + tombol ke form tambah)
2. `lib/features/home/home_providers.dart` — Riverpod provider gabungin total saldo + snapshot dari repository accounts & transactions yang udah ada

## Out of Scope
- Budget alert banner (plan 021, nyusul pas Insights/budget ada)

## Verification
1. Home nampilin total saldo bener (cross-check manual sama jumlah saldo tiap akun)
2. Snapshot income/expense bulan ini bener
3. Transaksi baru (dari plan 018) langsung muncul di "5 transaksi terakhir" tanpa perlu buka-tutup app
4. State kosong (fresh install, belum ada transaksi) → empty state actionable muncul
5. `flutter analyze` clean

## Next
Mobile Rilis 1 UI selesai secara fungsional (lokal doang, belum sync). Plan 020 — sync engine, penutup Rilis 1 mobile.

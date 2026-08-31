# 017 — Categories Feature

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: SCHEMA.md (`categories`), DESIGN.md §6 (More → Categories)

## Context
CRUD kategori di mobile, pola sama persis kayak accounts (plan 016) — local-first, dirty-tracking buat sync. Gak ada kategori bawaan (dikonfirmasi user), jadi first-run kategori kosong & user diarahin bikin sendiri.

## Scope
1. `lib/data/repository/categories_repository.dart` — wrap `CategoriesDao`, dirty-tracking sama kayak accounts
2. `lib/features/categories/categories_list_screen.dart` — list kategori grouped by type (Income/Expense), nested subkategori (indent/collapsible)
3. `lib/features/categories/category_form_screen.dart` — form tambah/edit (nama, tipe, parent kategori (opsional, dropdown filtered by type yang sama), icon picker sederhana dari set ikon Material bawaan, color picker dari palette terbatas biar konsisten)
4. `lib/features/categories/category_providers.dart` — Riverpod `StreamProvider`
5. Masuk ke `More` screen

## Out of Scope
- Sync ke backend (plan 020)

## Verification
1. Tambah kategori parent + subkategori → hierarki kebentuk bener di list
2. Tambah subkategori dgn tipe beda dari parent → ditolak di form (validasi client-side, mirror validasi backend plan 004)
3. Hapus kategori yang masih dipakai transaksi (setelah plan 018 ada) → soft delete, transaksi lama tetep nampilin nama kategori
4. `flutter analyze` clean

## Next
Plan 018 — transactions feature (list + tambah/edit).

# 013 — Local Database Schema (Drift)

Status: Kode ditulis, belum diverifikasi (nunggu SDK Flutter siap — lihat §Verification)
Sumber: SCHEMA.md (skema jadi acuan, mirror persis), TECH_STACK.md #2 (Drift + SQLCipher)

## Context
Local-first: semua data disimpan di device dulu (SQLite via Drift), sync ke backend belakangan (plan 020). Skema tabel Drift **mirror 1:1** sama `SCHEMA.md` (nama tabel/kolom sama persis, snake_case) — biar sync engine (yang udah dibangun di backend, plan 006) bisa jalan tanpa mapping ribet.

## Scope
1. `lib/data/local/tables/` — 1 file per tabel, Drift `Table` class: `accounts.dart`, `categories.dart`, `transactions.dart`, `budget_periods.dart`, `budgets.dart`, `recurring_rules.dart`, `goals.dart`. Kolom & constraint (enum via `TextColumn` + `check()`, FK via `references()`) ngikutin `SCHEMA.md` persis, termasuk kolom sync (`updated_at`, `deleted_at`) di semua tabel.
2. `lib/data/local/app_database.dart` — `@DriftDatabase` gabungin semua tabel, `schemaVersion = 1`
3. Enkripsi: buka koneksi Drift pake `SqlCipher` (`sqlcipher_flutter_libs`), encryption key digenerate random sekali & disimpen di `flutter_secure_storage` (bukan hardcode) — dipakai lagi tiap buka DB
4. `build_runner build` — generate kode Drift (`app_database.g.dart`)
5. `lib/data/local/daos/` — 1 DAO per tabel buat query dasar (insert/update/softDelete/watch-all), dipakai di plan-plan fitur berikutnya

## Out of Scope
- Migration/schema versioning (belum relevan, ini `schemaVersion=1` awal — strategi migrasi dari TECH_STACK.md #"Migration & Historikal Skema" dipakai pas ada perubahan skema nanti)
- Sync logic (plan 020)

## Verification
1. `build_runner build` sukses, gak ada error generate
2. App boot, DB ke-create di device, file DB ke-enkripsi (buka file `.db` langsung pake tool luar → gak kebaca plain, harus pake key)
3. Insert 1 row manual (misal lewat DAO di test) ke `accounts` → bisa di-query balik
4. `flutter analyze` clean

## Next
Plan 014 — app shell & navigasi (bottom nav + FAB + routing).

# 016 — Accounts Feature

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: SCHEMA.md (`accounts`), DESIGN.md #6 (More → Accounts)

## Context
CRUD dompet/akun di mobile, nulis ke local DB (Drift) dulu — bukan langsung ke backend (local-first, sync belakangan di plan 020). Saldo dihitung on-the-fly dari local DB (query Drift), konsisten sama pendekatan backend.

## Scope
1. `lib/data/repository/accounts_repository.dart` — wrap `AccountsDao` (plan 013), tandai row dirty (`pending_sync`) tiap create/update/delete lokal (kolom tambahan khusus lokal, gak ada di backend — dipakai internal buat tau apa yg perlu di-push, gak masuk skema sync payload)
2. `lib/features/accounts/accounts_list_screen.dart` — list akun (card: nama, tipe, saldo), tombol tambah
3. `lib/features/accounts/account_form_screen.dart` — form tambah/edit (nama, tipe chip Bank/Ewallet/Cash, saldo awal)
4. `lib/features/accounts/account_providers.dart` — Riverpod provider (`StreamProvider` dari Drift `watch()` query — list akun auto-update reaktif tiap ada perubahan)
5. Masuk ke `More` screen (plan 014 placeholder → diisi link ke `accounts_list_screen.dart`)

## Out of Scope
- Sync ke backend (plan 020)

## Verification
1. Tambah akun → langsung muncul di list (reactive, gak perlu refresh manual)
2. Edit nama akun → ke-update di list
3. Hapus akun → soft delete, ilang dari list
4. Data tetap ada abis app di-kill & dibuka lagi (persisted local)
5. `flutter analyze` clean

## Next
Plan 017 — categories feature.

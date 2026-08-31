# 022 — Recurring Rules & Goals UI

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: SCHEMA.md (`recurring_rules`, `goals`), backend plan 009/010

## Context
Rilis 3. Sama kayak Insights (plan 021) — konsumsi backend langsung (`dio`), bukan local-first, krn generation transaksi recurring dihandle scheduler backend (butuh online), dan goal progress juga agregat backend.

## Scope
1. `lib/data/remote/recurring_rules_api.dart`, `lib/data/remote/goals_api.dart`
2. `lib/features/recurring/recurring_list_screen.dart` — list rule aktif (nominal, interval, next_run_date), tambah/edit/hapus
3. `lib/features/recurring/recurring_form_screen.dart` — form (akun, kategori, tipe, nominal, interval unit+value, tanggal mulai/selesai)
4. `lib/features/goals/goals_list_screen.dart` — card per goal (progress bar, target vs current, tenggat)
5. `lib/features/goals/goal_form_screen.dart` — form tambah/edit goal
6. Masuk ke `More` screen (ganti placeholder dari plan 014)
7. Transaction form (plan 018) — tambah field opsional "Tag ke goal" (dropdown goal aktif) pas nambah transaksi

## Out of Scope
- Preview transaksi recurring yang bakal digenerate (backlog, sama kayak backend plan 009)

## Verification
1. Bikin recurring rule → transaksi ke-generate otomatis besok/pas due (cross-check via scheduler backend yang udah jalan)
2. Bikin goal, tag transaksi ke goal → progress bar update
3. `flutter analyze` clean

## Next
Plan 023 — reminders (local notification), penutup scope PRD di mobile.

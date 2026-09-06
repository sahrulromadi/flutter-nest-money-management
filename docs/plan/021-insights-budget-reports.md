# 021 — Insights: Budget & Reports UI

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: SCHEMA.md (`budget_periods`, `budgets`), backend plan 007/008, DESIGN.md #6 (Insights screen)

## Context
Rilis 2 — isi tab `Insights` yang dari plan 014 masih placeholder. Data budget/laporan diambil langsung dari backend (`GET /budgets`, `GET /reports/*`) via `dio`, **bukan** dari local Drift — beda dari fitur Rilis 1 (accounts/categories/transactions yang local-first). Alasan: agregasi budget/report udah dihitung backend (SQL agregat), gak perlu duplikat logic itu di client; data ini juga gak perlu offline-editable (read-mostly, budget-period create/update tetep butuh online).

## Scope
1. `lib/data/remote/budget_api.dart`, `lib/data/remote/reports_api.dart` — wrap endpoint backend plan 007/008
2. `lib/features/insights/insights_screen.dart`:
   - Selector periode (aktif + histori, dari `GET /budget-periods`)
   - Tombol "Mulai periode baru" (`POST /budget-periods`) — bikin bottom sheet konfirmasi tanggal mulai
   - List budget per kategori: progress bar (warna ikut threshold — hijau <80%, warning #4 DESIGN.md >80%, danger kalau lewat)
   - Chart cashflow trend & breakdown kategori — **load `dataviz` skill dulu sebelum nulis kode chart ini**, biar warna/style chart konsisten sama palette Karasuno + prinsip dataviz
3. `lib/features/insights/budget_form_sheet.dart` — bottom sheet set/edit limit budget per kategori
4. Home screen (plan 019) — tambah banner alert kalau ada budget nyaris/lewat limit (dari data yang sama)

## Out of Scope
- Custom budget period logic (udah di backend, mobile cuma trigger & display)

## Verification
1. Mulai periode baru → periode lama otomatis ketutup (cross-check backend), UI update
2. Set limit budget kategori → progress bar muncul, angka `spent` bener (dari backend)
3. Transaksi baru bikin `spent` lewat 80% → warna progress bar berubah jadi warning
4. Chart breakdown kategori & trend nampilin data bener, style konsisten (dataviz skill)
5. `flutter analyze` clean

## Next
Plan 022 — recurring rules & goals UI (Rilis 3).

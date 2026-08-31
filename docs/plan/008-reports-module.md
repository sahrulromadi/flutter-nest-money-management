# 008 — Reports Module

Status: Done
Sumber: PRD.md #5 Rilis 2 (dashboard laporan & grafik)

## Context
Read-only, agregasi query di atas `transactions`. Gak ada tabel baru — modul ini query lintas tabel yang udah ada.

## Scope
- `src/reports/reports.repository.ts` — raw SQL agregasi:
  - `getCategoryBreakdown(userId, periodStart, periodEnd)` — SUM amount group by category, exclude type=Transfer
  - `getCashflowTrend(userId, periodStart, periodEnd, granularity)` — SUM income vs expense per hari/minggu dalam rentang
  - `getSummary(userId, periodStart, periodEnd)` — total income, total expense, net cashflow
- `src/reports/reports.service.ts` — default rentang = periode budget aktif (dari `budget_periods`) kalau gak dikasih query param eksplisit
- `src/reports/reports.controller.ts`:
  - `GET /reports/summary?from=&to=`
  - `GET /reports/category-breakdown?from=&to=&type=Income|Expense`
  - `GET /reports/cashflow-trend?from=&to=`
- `src/reports/reports.module.ts`

## Out of Scope
- Export PDF/Excel (backlog PRD)
- Caching hasil agregasi (belum perlu, skala solo-user ringan)

## Verification
1. `GET /reports/summary` tanpa `from`/`to` → default pake periode budget aktif
2. Transaksi transfer gak muncul di `category-breakdown` (sesuai desain transfer di SCHEMA.md)
3. `cashflow-trend` totalnya konsisten sama `summary` (cross-check angka)
4. Lint clean, build sukses

## Next
Backend Rilis 2 selesai. Plan 009 — modul `recurring-rules` (Rilis 3).

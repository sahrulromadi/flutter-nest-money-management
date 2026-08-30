# 007 — Budget Periods & Budgets Module

Status: Done
Sumber: SCHEMA.md (`budget_periods`, `budgets`), PRD.md §5 Rilis 2

## Context
Custom budget period (manual, krn gajian gak tetap) + limit per kategori dalam periode aktif. DB udah enforce "cuma 1 periode aktif per user" via unique partial index (SCHEMA.md).

## Scope
- `src/budget-periods/budget-periods.repository.ts` — `create`, `findActiveByUser`, `findAllByUser` (histori), `closeActive` (set `ended_at`)
- `src/budget-periods/budget-periods.service.ts`:
  - `startNewPeriod(userId, startedAt)` — tutup periode aktif lama (`ended_at = startedAt - 1 hari`) dalam 1 transaction DB, baru insert periode baru
- `src/budget-periods/budget-periods.controller.ts`:
  - `POST /budget-periods` — mulai periode baru (trigger manual pas gajian cair)
  - `GET /budget-periods` — histori periode
  - `GET /budget-periods/active` — periode yang lagi jalan
- `src/budgets/budgets.repository.ts` — `create`, `findAllByPeriod`, `update`, `softDelete`, `getSpent(budgetId)` (SUM transaksi expense di kategori itu, dalam rentang tanggal periode)
- `src/budgets/budgets.service.ts` — validasi `category_id` type=Expense, unique per `(budget_period_id, category_id)`
- `src/budgets/budgets.controller.ts`:
  - `POST /budgets` — set limit kategori buat periode aktif
  - `GET /budgets?periodId=` — list budget + `spent`/`limit`/`percentage` tiap kategori
  - `PATCH /budgets/:id`, `DELETE /budgets/:id`
- `src/budgets/budgets.module.ts`, `src/budget-periods/budget-periods.module.ts`

## Out of Scope
- Notifikasi alert saat limit lewat (itu logic di mobile, backend cuma nyediain data `spent` vs `limit`)

## Verification
1. `POST /budget-periods` pertama kali → langsung aktif (`ended_at` null)
2. `POST /budget-periods` kedua → periode pertama otomatis `ended_at` keisi, periode kedua jadi aktif
3. `POST /budgets` limit kategori "Makan" 1jt di periode aktif → sukses
4. Transaksi expense kategori "Makan" 300rb dalam rentang periode aktif → `GET /budgets` nunjukin `spent=300000`
5. `POST /budgets` kategori sama di periode sama 2x → 409 (unique constraint)
6. Lint clean, build sukses

## Next
Plan 008 — modul `reports` (dashboard laporan & grafik, Rilis 2).

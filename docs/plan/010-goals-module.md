# 010 — Goals Module

Status: Done
Sumber: SCHEMA.md (`goals`), PRD.md §5 Rilis 3

## Context
Target nabung. `current_amount` gak disimpan (konsisten sama keputusan balance on-the-fly) — dihitung dari `SUM(transactions.amount) WHERE goal_id = ini`.

## Scope
- `src/goals/goals.repository.ts` — `create`, `findAllByUser` (+ `getProgress` join SUM transaksi ber-`goal_id`), `findByIdAndUser`, `update`, `softDelete`
- `src/goals/goals.service.ts` — validasi `account_id` (kalau diisi) milik user
- `src/goals/goals.controller.ts`:
  - `POST /goals`
  - `GET /goals` — list + `currentAmount`/`targetAmount`/`percentage` tiap goal
  - `GET /goals/:id`
  - `PATCH /goals/:id`, `DELETE /goals/:id`
- `dto/create-goal.dto.ts`, `dto/update-goal.dto.ts`
- `src/goals/goals.module.ts`

## Out of Scope
- Reminder progress goal (masuk plan 011)

## Verification
1. Bikin goal target 10jt
2. Bikin transaksi (expense kategori "Tabungan" atau transfer) dengan `goal_id` = goal itu, amount 500rb → `GET /goals/:id` nunjukin `currentAmount=500000`, `percentage=5`
3. Hapus transaksi itu → `currentAmount` balik ke 0 (on-the-fly, otomatis konsisten)
4. Lint clean, build sukses

## Next
Plan 011 — reminder/notifikasi data (Rilis 3, penutup backend scope PRD).

# 005 — Transactions Module

Status: Done
Sumber: SCHEMA.md (`transactions`), PRD.md §5 Rilis 1, §9 (edge case transfer)

## Context
Modul inti — CRUD transaksi (income/expense/transfer). DB constraint (CHECK) udah nge-enforce sebagian besar aturan (transfer wajib `transfer_to_account_id`, non-transfer wajib `category_id`, gak bisa transfer ke akun sendiri) — service tinggal validasi hal yang gak kecover CHECK (misal: `account_id`/`category_id`/`goal_id` harus milik user yang login, akun & kategori harus ada & belum di-soft-delete).

## Scope
- `src/transactions/transactions.repository.ts` — raw SQL: `create`, `findAllByUser` (filter: `account_id`, `category_id`, rentang tanggal, pagination), `findByIdAndUser`, `update`, `softDelete`
- `src/transactions/transactions.service.ts`:
  - Validasi `account_id` (dan `transfer_to_account_id` kalau transfer) milik user & aktif
  - Validasi `category_id` (kalau bukan transfer) milik user & tipe (Income/Expense) match `transaction.type`
  - Kalau `goal_id` diisi → validasi goal milik user
- `src/transactions/transactions.controller.ts`:
  - `POST /transactions`
  - `GET /transactions` — list + filter query params
  - `GET /transactions/:id`
  - `PATCH /transactions/:id`
  - `DELETE /transactions/:id` — soft delete
- `dto/create-transaction.dto.ts` (custom validator: kalau `type=Transfer` maka `transferToAccountId` required & `categoryId` harus kosong, sebaliknya kalau bukan transfer), `dto/update-transaction.dto.ts`, `dto/query-transactions.dto.ts`
- `src/transactions/transactions.module.ts`

## Out of Scope
- Recurring generation (plan 009)
- Sync push/pull (plan 006)

## Verification
1. Create income → saldo akun (dari plan 003 `getBalance`) naik sesuai amount
2. Create expense → saldo turun
3. Create transfer antar 2 akun → saldo akun asal turun, akun tujuan naik, `category_id` NULL
4. Create transfer ke akun yang sama → 400 (DB constraint kena, service harus translate jadi error message yang jelas, bukan raw Postgres error)
5. Delete transaksi → saldo balik kayak sebelum transaksi itu ada (krn on-the-fly SUM otomatis exclude yang soft-deleted)
6. Lint clean, build sukses

## Next
Plan 006 — modul `sync` (push/pull, penutup Rilis 1 biar mobile app bisa multi-device).

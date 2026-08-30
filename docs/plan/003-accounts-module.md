# 003 — Accounts Module

Status: Done
Sumber: SCHEMA.md (`accounts`), PRD.md §5 Rilis 1

## Context
Modul dompet/akun. Semua endpoint otomatis protected (global `JwtAuthGuard` dari plan 002). Saldo dihitung on-the-fly (keputusan SCHEMA.md), bukan kolom tersimpan.

## Scope
- `src/accounts/accounts.repository.ts` — raw SQL: `create`, `findAllByUser`, `findByIdAndUser`, `update`, `softDelete`, `getBalance(accountId)` (query `initial_balance + SUM` transaksi terkait, handle 3 arah: expense/transfer-out kurangi, income/transfer-in tambah — sesuai SCHEMA.md)
- `src/accounts/accounts.service.ts` — business logic, validasi akun milik user yang login (`req.user.sub`)
- `src/accounts/accounts.controller.ts`:
  - `POST /accounts` — buat akun
  - `GET /accounts` — list akun + saldo tiap akun
  - `GET /accounts/:id` — detail akun + saldo
  - `PATCH /accounts/:id` — update (name, type)
  - `DELETE /accounts/:id` — soft delete
- `dto/create-account.dto.ts`, `dto/update-account.dto.ts` — validasi `type` cuma boleh `Bank`/`Ewallet`/`Cash`
- `src/accounts/accounts.module.ts`

## Out of Scope
- Transfer/transaksi (modul 005 `transactions`)

## Verification
1. `POST /accounts` tanpa token → 401 (guard beneran jalan, verifikasi ulang dari plan 002 item 5)
2. `POST /accounts` dgn token → 201, akun kebuat
3. `GET /accounts` → balance akun baru = `initial_balance` (belum ada transaksi)
4. `DELETE /accounts/:id` → soft delete, gak muncul lagi di `GET /accounts`
5. Akun milik user lain (kalau ada, buat skip test krn single-user) gak bisa diakses — cukup pastiin query selalu filter `user_id = req.user.sub`
6. Lint clean, build sukses

## Next
Plan 004 — modul `categories`.

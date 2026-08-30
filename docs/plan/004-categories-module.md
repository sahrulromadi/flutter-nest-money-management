# 004 — Categories Module

Status: Done
Sumber: SCHEMA.md (`categories`), PRD.md §5 Rilis 1

## Context
Gak ada kategori bawaan (dikonfirmasi user) — semua kategori dibuat manual. Support subkategori via `parent_id`.

## Scope
- `src/categories/categories.repository.ts` — raw SQL: `create`, `findAllByUser` (include nested/parent info), `findByIdAndUser`, `update`, `softDelete`
- `src/categories/categories.service.ts` — validasi: `parent_id` (kalau diisi) harus punya `type` yang sama & milik user yang sama
- `src/categories/categories.controller.ts`:
  - `POST /categories`
  - `GET /categories` — list, bisa filter `?type=Income|Expense`
  - `GET /categories/:id`
  - `PATCH /categories/:id`
  - `DELETE /categories/:id` — soft delete (kategori lama dipakai transaksi historis tetap valid, PRD §9)
- `dto/create-category.dto.ts`, `dto/update-category.dto.ts` — `type` cuma `Income`/`Expense`
- `src/categories/categories.module.ts`

## Out of Scope
- Icon/color picker UI (itu urusan mobile)

## Verification
1. `POST /categories` bikin parent + child (subkategori) → sukses, `parent_id` konsisten
2. `POST /categories` subkategori dengan `type` beda dari parent → ditolak (400)
3. `DELETE /categories/:id` yang masih dipakai transaksi → tetep bisa (soft delete), data transaksi lama gak rusak
4. Lint clean, build sukses

## Next
Plan 005 — modul `transactions` (inti aplikasi: CRUD + logic saldo + transfer).

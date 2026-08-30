# 006 — Sync Module

Status: Done
Sumber: TECH_STACK.md §6 (sync strategy), SCHEMA.md (kolom `updated_at`/`deleted_at` tiap tabel)

## Context
Penutup Rilis 1 — tanpa ini mobile app (local-first) gak bisa punya data yang konsisten lintas device. Generik: 1 mekanisme push/pull yang jalan buat semua tabel sync-able (`accounts`, `categories`, `transactions`, `budget_periods`, `budgets`, `recurring_rules`, `goals`), bukan endpoint per tabel — biar gak ada 7x kode yang isinya sama persis.

## Scope
- `src/sync/sync.constants.ts` — daftar tabel sync-able + whitelist kolom tiap tabel (cegah client kirim kolom sembarangan)
- `src/sync/sync.repository.ts`:
  - `upsert(table, row)` — `INSERT ... ON CONFLICT (id) DO UPDATE` tapi cuma jalan kalau `EXCLUDED.updated_at > <table>.updated_at` (last-write-wins beneran di level query, bukan di app code — hindari race condition)
  - `findChangedSince(table, userId, since)` — `SELECT * WHERE user_id = $1 AND updated_at > $2` (termasuk yang `deleted_at IS NOT NULL`, biar client tau harus hapus row lokal juga)
- `src/sync/sync.service.ts`:
  - `push(userId, changesByTable)` — loop tabel sesuai urutan dependency FK (accounts/categories/goals dulu, baru transactions, dst — sama urutan kayak migration), `upsert` tiap row, paksa `user_id` dari token (bukan dari payload client, cegah user nyuntik data ke user lain — meski single-user app, tetep validasi)
  - `pull(userId, since)` — loop semua tabel, kembaliin `{ table: rows[] }`
- `src/sync/sync.controller.ts`:
  - `POST /sync/push` — body: `{ [table]: Row[] }`
  - `GET /sync/pull?since=<ISO timestamp>` — kalau `since` kosong, berarti initial sync (semua data)
- `dto/sync-push.dto.ts` — validasi shape per tabel pake whitelist dari constants

## Out of Scope
- Realtime push (WebSocket) — polling/manual-trigger cukup buat v1
- Sync buat tabel yang belum ada (recurring_rules/goals/budget* — kolomnya udah didesain sync-ready dari awal, jadi otomatis kecover pas modul itu jadi, gak perlu ubah sync module lagi)

## Verification
1. `POST /sync/push` kirim 1 account baru (id UUID dari client) → tersimpan, `GET /sync/pull` balikin row itu
2. Push row yang sama dengan `updated_at` lebih lama dari yang di server → diabaikan (last-write-wins), data server gak keubah
3. Push row dengan `updated_at` lebih baru → di-apply
4. Pull dengan `since` = row yang di-soft-delete abis pull sebelumnya → row muncul lagi di hasil pull (dengan `deleted_at` keisi), biar client tau harus hapus lokal
5. Push data dengan `user_id` field beda dari token → tetep kesimpen ke `user_id` token (diabaikan/di-override), bukan user_id dari payload
6. Lint clean, build sukses

## Next
Rilis 1 backend selesai secara fungsional. Plan 007 — modul `budget-periods` + `budgets` (Rilis 2).

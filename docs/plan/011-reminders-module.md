# 011 — Reminders Module

Status: Done (scope dibatasin sesuai catatan; push notif infra masih pending)
Sumber: PRD.md #5 Rilis 3 (reminder/notifikasi)

## Context
PRD minta 2 jenis reminder: tagihan jatuh tempo (dari `recurring_rules`) & reminder catat pengeluaran harian (kalau belum ada transaksi hari itu). **Belum diputusin**: mekanisme notifikasi ke device (push via FCM/APNs, atau local notification di mobile yang di-schedule sendiri berdasarkan data dari backend). Plan ini scope-nya dibatasin ke bagian yang gak tergantung keputusan itu: backend nyediain data-nya aja, mobile yang nentuin gimana nampilinnya (local notification paling simpel, gak perlu push infra tambahan di v1).

## Scope
- `src/reminders/reminders.repository.ts`:
  - `findUpcomingBills(userId, withinDays)` — recurring rules dengan `next_run_date` dalam N hari ke depan
  - `hasTransactionToday(userId)` — boolean, cek ada transaksi dengan `occurred_at = CURRENT_DATE`
- `src/reminders/reminders.service.ts`
- `src/reminders/reminders.controller.ts`:
  - `GET /reminders/upcoming-bills?withinDays=3`
  - `GET /reminders/daily-check` — `{ hasTransactionToday: boolean }`
- `src/reminders/reminders.module.ts`

## Out of Scope (butuh keputusan lanjut, jangan dikerjain sebelum diputusin)
- Push notification infra (FCM/APNs) — kalau nanti mobile app di-background dan tetep butuh notif walau app ketutup, baru perlu ini
- Scheduling/trigger waktu notif spesifik (jam berapa reminder muncul) — itu logic di mobile pake data dari endpoint ini

## Verification
1. Bikin recurring rule `next_run_date` = 2 hari lagi → muncul di `GET /reminders/upcoming-bills?withinDays=3`
2. Belum ada transaksi hari ini → `daily-check` return `hasTransactionToday: false`
3. Lint clean, build sukses

## Next
Backend scope PRD (Rilis 1-3) selesai secara fungsional. Lanjut ke development mobile (Flutter) — plan terpisah, mulai dari local DB schema (Drift) yang mirror `SCHEMA.md`.

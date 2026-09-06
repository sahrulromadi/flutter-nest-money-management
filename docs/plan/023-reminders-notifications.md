# 023 — Reminders (Local Notification)

> **DIBATALKAN & DIHAPUS (plan 033).** Fitur reminder tagihan jatuh tempo dinilai kurang
> berguna — user pakai Transaksi Berulang buat transaksi rutin (parkir dll), bukan tagihan
> yang perlu diingatkan. Seluruh kode reminder + `flutter_local_notifications` + `timezone`
> dibuang.

Status: Kode ditulis, belum diverifikasi (nunggu SDK)
Sumber: PRD.md #5 Rilis 3, backend plan 011 (`/reminders/*`)

## Context
Backend cuma nyediain data (plan 011) — mekanisme notifikasi diputusin di sini: **local notification** yang dijadwalin dari data backend, bukan push/FCM (sesuai keputusan di plan 011, cukup buat v1 solo-user).

## Scope
1. Dependency: `flutter_local_notifications`
2. `lib/data/remote/reminders_api.dart` — wrap `GET /reminders/upcoming-bills`, `GET /reminders/daily-check`
3. `lib/features/reminders/reminder_scheduler.dart`:
   - Tiap app dibuka/resume (atau via periodic background fetch kalau tersedia) → panggil `upcoming-bills`, schedule local notification H-1 dari `next_run_date` tiap rule
   - `daily-check` tiap sore (jadwal tetap, misal jam 8 malam) → kalau `hasTransactionToday=false`, kirim local notification reminder catat
4. Setting toggle di `More` → Settings: enable/disable tiap jenis reminder (disimpen di `flutter_secure_storage` atau `SharedPreferences`)

## Out of Scope
- Push notification (FCM) — kalau nanti app perlu notif walau ke-kill total, baru dipertimbangkan ulang (butuh keputusan infra tambahan)

## Verification
1. Ada recurring rule due besok → notif lokal muncul
2. Belum ada transaksi sampe jam yang di-set → notif reminder muncul
3. Toggle off salah satu jenis reminder → notif jenis itu berhenti muncul
4. `flutter analyze` clean

## Next
Scope PRD (Rilis 1-3) selesai di mobile & backend. Lanjut: deployment backend (VPS) + build & install APK ke device buat pemakaian harian beneran.

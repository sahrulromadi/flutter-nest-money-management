# 033 — Hapus Reminder + Fix Bug Budget/Laporan

Status: **SELESAI** (2026-09-06). Dari testing di device.

## Item 1 — Hapus fitur reminder tagihan
User: Transaksi Berulang dipakai buat transaksi rutin (parkir Rp 2.000/hari), bukan tagihan
yang perlu diingatkan. Fitur reminder ga guna.

Dihapus:
- `mobile/lib/features/reminders/` (reminder_scheduler, reminder_settings, reminder_settings_tiles)
- `mobile/lib/data/notifications/notification_service.dart`
- `RecurringRulesDao.findUpcoming`
- `main.dart` — `reminderStartupProvider` watch
- `more_screen.dart` — `ReminderSettingsTiles`, `NotificationService.cancelAll()` di logout
- `pubspec.yaml` — `flutter_local_notifications`, `timezone`
- plan 023 & 029 Item 4 ditandai batal

Backend `src/reminders/` udah dihapus di plan 029 Item 4 — ga ada perubahan BE lagi.

## Item 2 — Fix bug: transaksi hari ini ga masuk laporan/budget
`_occurredAt = DateTime.now()` disimpan **dengan jam**. Range laporan `to = today` =
tengah malam. Query `occurred_at BETWEEN from AND today-00:00` → transaksi hari ini (jam
14:30) ke-exclude sampai besok.

Fix:
- `transactions_repository.dart`: `_dateOnly()` helper — `occurred_at` selalu date-only di
  `create` / `update` / `createUncategorized` (konsisten sama serializer sync + recurring generator).
- `insights_providers.dart` `_rangeFor`: `to` pakai `_endOfDay()` (23:59:59.999) — catch data
  lama yang masih ber-jam.

## Item 3 — Fix bug: budget baru ga refresh
`budgetsWithProgressProvider` nested infinite stream:
`await for (budgets) { yield* watchCategoryBreakdown()... }` — inner stream infinite, ga
pernah return → emisi `budgets` ke-2 (tambah/hapus budget) ga ke-consume.

Fix: pisah jadi `_viewedBudgetsProvider` (stream tunggal) + `budgetsWithProgressProvider`
jadi `Provider<AsyncValue<...>>` yang `ref.watch` dua stream (`_viewedBudgetsProvider` +
`categoryBreakdownProvider`) lalu gabung. Dua-duanya reaktif.

## Verifikasi
1. `flutter analyze` clean, `pub get` OK.
2. Grep `reminder|NotificationService|timezone|flutter_local_notif` di lib → 0 hasil.
3. Tambah transaksi hari ini (tanpa ubah tanggal) → langsung muncul di budget spent,
   breakdown, cashflow, summary.
4. Tambah budget → langsung muncul di list (ga perlu keluar-masuk Insights).
5. More → ga ada toggle "Reminder tagihan jatuh tempo".
6. `flutter build apk` sukses (tanpa plugin notifikasi).

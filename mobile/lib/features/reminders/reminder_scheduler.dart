import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/notification_service.dart';
import '../../data/remote/api_client_provider.dart';
import '../../data/remote/reminders_api.dart';
import '../../shared/currency_formatter.dart';
import 'reminder_settings.dart';

final remindersApiProvider = Provider<RemindersApi>((ref) {
  return RemindersApi(ref.watch(apiClientProvider).dio);
});

/// Dipanggil tiap app dibuka/resume (main.dart) — fetch data reminder dari
/// backend, jadwalin local notification. Sesuai plan 011/023: backend cuma
/// nyediain data, mobile yang jadwalin notifnya.
class ReminderScheduler {
  ReminderScheduler(this._api, this._settings);

  final RemindersApi _api;
  final ReminderSettings _settings;

  Future<void> refresh() async {
    await NotificationService.instance.init();

    if (_settings.billsEnabled) {
      await _scheduleBills();
    }
  }

  Future<void> _scheduleBills() async {
    final bills = await _api.upcomingBills(withinDays: 3);
    for (final bill in bills) {
      final reminderTime = bill.nextRunDate.subtract(const Duration(days: 1));
      if (reminderTime.isBefore(DateTime.now())) continue;
      await NotificationService.instance.scheduleBillReminder(
        // hashCode id bisa collide teoritis, tapi cukup buat skala solo-user
        id: bill.id.hashCode,
        title: 'Tagihan jatuh tempo besok',
        body: formatRupiah(bill.amount),
        whenLocal: DateTime(reminderTime.year, reminderTime.month, reminderTime.day, 9),
      );
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(ref.watch(remindersApiProvider), ref.watch(reminderSettingsProvider));
});

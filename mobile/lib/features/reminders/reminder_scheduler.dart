import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database_provider.dart';
import '../../data/local/daos/recurring_rules_dao.dart';
import '../../data/notifications/notification_service.dart';
import '../../shared/currency_formatter.dart';
import '../auth/current_user_provider.dart';
import 'reminder_settings.dart';

/// Jadwalin local notification buat tagihan (recurring rule Expense) yang
/// jatuh tempo. Sejak plan 029 murni lokal — baca dari Drift, ga butuh backend.
class ReminderScheduler {
  ReminderScheduler(this._ruleDao, this._settings);

  final RecurringRulesDao _ruleDao;
  final ReminderSettings _settings;

  Future<void> refresh(String userId) async {
    await NotificationService.instance.init();
    if (!_settings.billsEnabled) return;

    final now = DateTime.now();
    final until = DateTime(now.year, now.month, now.day + 3);
    final bills = await _ruleDao.findUpcoming(userId, until);

    for (final bill in bills) {
      if (bill.type != 'Expense') continue;
      final reminderTime = bill.nextRunDate.subtract(const Duration(days: 1));
      if (reminderTime.isBefore(now)) continue;
      await NotificationService.instance.scheduleBillReminder(
        id: bill.id.hashCode,
        title: 'Tagihan jatuh tempo besok',
        body: formatRupiah(bill.amount),
        whenLocal: DateTime(
          reminderTime.year,
          reminderTime.month,
          reminderTime.day,
          9,
        ),
      );
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReminderScheduler(db.recurringRulesDao, ref.watch(reminderSettingsProvider));
});

/// Jalanin sekali pas app launch (di-`watch` di main.dart). Best-effort.
final reminderStartupProvider = FutureProvider<void>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;
  await ref.read(reminderSchedulerProvider).refresh(userId);
});

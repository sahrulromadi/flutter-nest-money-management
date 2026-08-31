import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();
const _billsKey = 'reminder_bills_enabled';
const _dailyKey = 'reminder_daily_enabled';

class ReminderSettings {
  const ReminderSettings({required this.billsEnabled, required this.dailyEnabled});

  final bool billsEnabled;
  final bool dailyEnabled;

  ReminderSettings copyWith({bool? billsEnabled, bool? dailyEnabled}) => ReminderSettings(
        billsEnabled: billsEnabled ?? this.billsEnabled,
        dailyEnabled: dailyEnabled ?? this.dailyEnabled,
      );
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
  ReminderSettingsController.new,
);

class ReminderSettingsController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings(billsEnabled: true, dailyEnabled: true);
  }

  Future<void> _load() async {
    final bills = await _secureStorage.read(key: _billsKey);
    final daily = await _secureStorage.read(key: _dailyKey);
    state = ReminderSettings(
      billsEnabled: bills != 'false',
      dailyEnabled: daily != 'false',
    );
  }

  Future<void> setBillsEnabled(bool value) async {
    await _secureStorage.write(key: _billsKey, value: value.toString());
    state = state.copyWith(billsEnabled: value);
  }

  Future<void> setDailyEnabled(bool value) async {
    await _secureStorage.write(key: _dailyKey, value: value.toString());
    state = state.copyWith(dailyEnabled: value);
  }
}

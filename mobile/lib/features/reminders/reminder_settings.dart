import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();
const _billsKey = 'reminder_bills_enabled';

class ReminderSettings {
  const ReminderSettings({required this.billsEnabled});

  final bool billsEnabled;

  ReminderSettings copyWith({bool? billsEnabled}) =>
      ReminderSettings(billsEnabled: billsEnabled ?? this.billsEnabled);
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
  ReminderSettingsController.new,
);

class ReminderSettingsController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings(billsEnabled: true);
  }

  Future<void> _load() async {
    final bills = await _secureStorage.read(key: _billsKey);
    state = ReminderSettings(billsEnabled: bills != 'false');
  }

  Future<void> setBillsEnabled(bool value) async {
    await _secureStorage.write(key: _billsKey, value: value.toString());
    state = state.copyWith(billsEnabled: value);
  }
}

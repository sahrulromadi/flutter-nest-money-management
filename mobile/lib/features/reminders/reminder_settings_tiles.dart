import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_settings.dart';

class ReminderSettingsTiles extends ConsumerWidget {
  const ReminderSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final controller = ref.read(reminderSettingsProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.event_note_outlined),
          title: const Text('Reminder tagihan jatuh tempo'),
          value: settings.billsEnabled,
          onChanged: controller.setBillsEnabled,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.edit_calendar_outlined),
          title: const Text('Reminder catat harian'),
          value: settings.dailyEnabled,
          onChanged: controller.setDailyEnabled,
        ),
      ],
    );
  }
}

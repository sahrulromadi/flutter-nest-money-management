import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _billChannel = AndroidNotificationDetails(
  'upcoming_bills',
  'Tagihan Jatuh Tempo',
  channelDescription: 'Reminder tagihan/transaksi berulang yang mau jatuh tempo',
  importance: Importance.defaultImportance,
);

const _dailyChannel = AndroidNotificationDetails(
  'daily_check',
  'Reminder Catat Harian',
  channelDescription: 'Reminder kalau belum ada transaksi tercatat hari ini',
  importance: Importance.defaultImportance,
);

/// Wrap `flutter_local_notifications` — dipake sesuai keputusan plan 011/023:
/// local notification, bukan push/FCM.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleBillReminder({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(whenLocal, tz.local),
      const NotificationDetails(android: _billChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> scheduleDailyCheckReminder({
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      0, // id tetap — reminder harian cuma 1 instance aktif, replace tiap dijadwal ulang
      'Belum catat transaksi hari ini',
      'Yuk catat pemasukan/pengeluaran hari ini biar gak kelewat',
      scheduled,
      const NotificationDetails(android: _dailyChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _billChannel = AndroidNotificationDetails(
  'upcoming_bills',
  'Tagihan Jatuh Tempo',
  channelDescription: 'Reminder tagihan/transaksi berulang yang mau jatuh tempo',
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

    // plan 024: fitur "reminder catat harian" dihapus. Batalin notif harian
    // (id tetap 0) yang mungkin udah ke-schedule di device dari versi lama.
    await _plugin.cancel(0);

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

  Future<void> cancelAll() => _plugin.cancelAll();
}

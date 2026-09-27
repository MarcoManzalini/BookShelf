import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// The few notification calls the reminders need, so they can be tested
/// without the plugin.
abstract interface class ReminderScheduler {
  /// Asks the system for permission to show notifications.
  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
  });

  Future<void> cancel(int id);
}

class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  static const _channelId = 'reading_reminders';

  /// Initializes once, without asking for permission: that happens only when
  /// the reader turns reminders on.
  Future<void> _init() => _ready ??= _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
  }) async {
    await _init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // A fixed instant: the local wall-clock time was already worked out by
      // Dart, daylight saving included, so no time zone database is needed.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channelId, channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      // A few minutes late is fine and needs no exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }
}

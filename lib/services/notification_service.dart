import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      // getLocalTimezone() returns a String timezone identifier (e.g. "Europe/Budapest")
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
    );
    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
  }

  Future<void> scheduleSessionComplete(DateTime at) async {
    await initialize();
    await _plugin.cancel(id: 100);
    await _plugin.zonedSchedule(
      id: 100,
      title: 'Great job!',
      body: 'Your focus session is complete. Claim your rewards.',
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_session',
          'Focus sessions',
          channelDescription: 'Timer completion notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelSessionComplete() async {
    await initialize();
    await _plugin.cancel(id: 100);
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var time =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!time.isAfter(now)) {
      time = time.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: 200,
      title: 'Lumi is ready to study',
      body: 'Complete one focus session to build your streak today.',
      scheduledDate: time,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminders',
          channelDescription: 'Daily study reminder notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _plugin.cancel(id: 200);
  }
}

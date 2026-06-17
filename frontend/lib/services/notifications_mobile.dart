import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
bool get notificationsSupported => true;
class NotificationsService {
  static final NotificationsService _instance = NotificationsService._();
  factory NotificationsService() => _instance;
  NotificationsService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _channelId = 'circe_health';
  static const AndroidNotificationChannel _channelDef =
      AndroidNotificationChannel(
    _channelId,
    'Circe · Salud',
    description: 'Recordatorios de actividad, rutinas y descanso',
    importance: Importance.max,
  );
  static const _details = AndroidNotificationDetails(
    _channelId,
    'Circe · Salud',
    channelDescription: 'Recordatorios de actividad, rutinas y descanso',
    importance: Importance.max,
    priority: Priority.high,
    icon: 'ic_stat_circe', 
    largeIcon: DrawableResourceAndroidBitmap('ic_circe_large'), 
  );
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();
    const android = AndroidInitializationSettings('ic_stat_circe');
    await _plugin.initialize(const InitializationSettings(android: android));
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channelDef);
    _ready = true;
  }
  Future<void> _configureLocalTimeZone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      final tzNow = tz.TZDateTime.now(tz.local);
      final sysNow = DateTime.now();
      if (tzNow.hour == sysNow.hour) return; 
    } catch (_) {}
    try {
      final offset = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (_) {}
  }
  Future<bool> requestPermission() async {
    if (!_ready) await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final pluginGranted = await android?.requestNotificationsPermission();
    if (pluginGranted == true) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
  Future<void> openSettings() async {
    await openAppSettings();
  }
  Future<void> requestBatteryExemption() async {
    try {
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {}
  }
  Future<void> showNow(String title, String body) async {
    if (!_ready) await init();
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        title,
        body,
        const NotificationDetails(android: _details));
  }
  Future<void> scheduleDaily(
      int id, int hour, int minute, String title, String body) async {
    if (!_ready) await init();
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(android: _details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  Future<void> scheduleInMinutes(
      int id, int minutes, String title, String body) async {
    if (!_ready) await init();
    final when =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(android: _details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  Future<void> cancel(int id) async {
    if (!_ready) await init();
    await _plugin.cancel(id);
  }
}
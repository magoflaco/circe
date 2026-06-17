bool get notificationsSupported => false;
class NotificationsService {
  Future<void> init() async {}
  Future<bool> requestPermission() async => false;
  Future<bool> hasPermission() async => false;
  Future<void> openSettings() async {}
  Future<void> requestBatteryExemption() async {}
  Future<void> showNow(String title, String body) async {}
  Future<void> scheduleDaily(
      int id, int hour, int minute, String title, String body) async {}
  Future<void> scheduleInMinutes(
      int id, int minutes, String title, String body) async {}
  Future<void> cancel(int id) async {}
}
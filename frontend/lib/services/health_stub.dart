bool get healthSupported => false;
class HealthService {
  Stream<int> get steps => const Stream.empty();
  int get today => 0;
  List<int> get hourly => List<int>.filled(24, 0);
  Future<bool> requestPermission() async => false;
  Future<bool> hasPermission() async => false;
  Future<int> savedToday() async => 0;
  Future<void> start() async {}
  Future<void> stop() async {}
  Future<int> getGoal() async => 8000;
  Future<void> setGoal(int goal) async {}
  Future<List<int>> hourlySteps() async => List<int>.filled(24, 0);
  Future<Map<String, int>> history(int days) async => {};
}
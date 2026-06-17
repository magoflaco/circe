import 'dart:async';
import 'dart:convert';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
bool get healthSupported => true;
class HealthService {
  StreamSubscription<StepCount>? _sub;
  final _controller = StreamController<int>.broadcast();
  int _today = 0;
  List<int> _hourly = List<int>.filled(24, 0);
  bool _needBaseline = true; 
  Stream<int> get steps => _controller.stream;
  int get today => _today;
  List<int> get hourly => List<int>.unmodifiable(_hourly);
  static String _dateKey([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
  Future<bool> requestPermission() async =>
      (await Permission.activityRecognition.request()).isGranted;
  Future<bool> hasPermission() async =>
      Permission.activityRecognition.isGranted;
  Future<int> savedToday() async {
    final prefs = await SharedPreferences.getInstance();
    _today = prefs.getInt('steps_${_dateKey()}') ?? 0;
    _hourly = _readHourly(prefs, _dateKey());
    return _today;
  }
  List<int> _readHourly(SharedPreferences p, String date) {
    final raw = p.getString('steps_hourly_$date');
    if (raw == null) return List<int>.filled(24, 0);
    try {
      final list = (jsonDecode(raw) as List).map((e) => e as int).toList();
      if (list.length == 24) return list;
    } catch (_) {}
    return List<int>.filled(24, 0);
  }
  Future<void> start() async {
    await _sub?.cancel();
    _needBaseline = true; 
    _sub = Pedometer.stepCountStream.listen(_onStep, onError: (_) {});
  }
  Future<void> _onStep(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dateKey(now);
    final cum = event.steps;
    if (prefs.getString('step_last_date') != today) {
      _today = 0;
      _hourly = List<int>.filled(24, 0);
      await prefs.setInt('steps_$today', 0);
      await prefs.setString('steps_hourly_$today', jsonEncode(_hourly));
      await prefs.setString('step_last_date', today);
      await prefs.setInt('step_last_cum', cum);
      _needBaseline = false;
      _controller.add(_today);
      return;
    }
    if (_needBaseline) {
      await prefs.setInt('step_last_cum', cum);
      _needBaseline = false;
      _today = prefs.getInt('steps_$today') ?? 0;
      _hourly = _readHourly(prefs, today);
      _controller.add(_today);
      return;
    }
    final lastCum = prefs.getInt('step_last_cum') ?? cum;
    int delta = cum >= lastCum ? cum - lastCum : cum;
    if (delta < 0 || delta > 50000) delta = 0; 
    _hourly = _readHourly(prefs, today);
    _hourly[now.hour] = _hourly[now.hour] + delta;
    _today = _hourly.fold(0, (a, b) => a + b);
    await prefs.setString('steps_hourly_$today', jsonEncode(_hourly));
    await prefs.setInt('steps_$today', _today);
    await prefs.setInt('step_last_cum', cum);
    _controller.add(_today);
  }
  Future<void> stop() async => _sub?.cancel();
  Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('step_goal') ?? 8000;
  }
  Future<void> setGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_goal', goal);
  }
  Future<List<int>> hourlySteps() async {
    final prefs = await SharedPreferences.getInstance();
    return _readHourly(prefs, _dateKey());
  }
  Future<Map<String, int>> history(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, int>{};
    for (int i = 0; i < days; i++) {
      final key = _dateKey(DateTime.now().subtract(Duration(days: i)));
      out[key] = prefs.getInt('steps_$key') ?? 0;
    }
    return out;
  }
}
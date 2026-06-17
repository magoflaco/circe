import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_provider.dart';
import '../services/health_service.dart';
import '../services/notifications_service.dart';
import '../theme.dart';
import '../widgets.dart';
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}
class _ActivityScreenState extends State<ActivityScreen> {
  final _health = HealthService();
  final _notif = NotificationsService();
  StreamSubscription<int>? _sub;
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));
  bool _goalCelebrated = false; 
  bool _started = false;
  int _steps = 0;
  int _goal = 8000;
  Map<String, int> _history = {};
  List<int> _hourly = List<int>.filled(24, 0);
  int? _age;
  double? _bmi;
  double? _weight;
  double? _height;
  int _recSleepHours = 8;
  bool _remGoal = false; 
  bool _remSleep = false; 
  bool _congratsShown = false;
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  @override
  void initState() {
    super.initState();
    _load();
  }
  @override
  void dispose() {
    _sub?.cancel();
    _confetti.dispose();
    super.dispose();
  }
  void _celebrate() {
    if (_goalCelebrated) return;
    _goalCelebrated = true;
    _confetti.play();
  }
  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
  Future<void> _load() async {
    final goal = await _health.getGoal();
    final hist = await _health.history(7);
    final saved = await _health.savedToday();
    final hourly = await _health.hourlySteps();
    final prefs = await SharedPreferences.getInstance();
    final wasEnabled = prefs.getBool('steps_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _history = hist;
      _steps = saved;
      _hourly = hourly;
      _remGoal = prefs.getBool('rem_goal') ?? false;
      _remSleep = prefs.getBool('rem_sleep') ?? false;
      _sleepTime = _timeFrom(prefs, 'rem_sleep_t', _sleepTime);
      _congratsShown = prefs.getBool('congrats_${_today()}') ?? false;
    });
    if (_goal > 0 && _steps >= _goal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
    if (wasEnabled && await _health.hasPermission()) {
      await _startCounting();
    }
    _loadProfile();
  }
  TimeOfDay _timeFrom(SharedPreferences p, String key, TimeOfDay fb) {
    final v = p.getString(key);
    if (v == null) return fb;
    final parts = v.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  Future<void> _startCounting() async {
    await _sub?.cancel();
    await _health.start();
    _sub = _health.steps.listen(_onSteps);
    if (mounted) setState(() => _started = true);
  }
  void _onSteps(int s) {
    if (!mounted) return;
    final crossed = _steps < _goal && s >= _goal;
    setState(() {
      _steps = s;
      _hourly = _health.hourly;
    });
    if (crossed && _goal > 0) _celebrate();
    _maybeCongrats();
  }
  Future<void> _maybeCongrats() async {
    if (!_remGoal || _congratsShown || _steps < _goal) return;
    _congratsShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('congrats_${_today()}', true);
    try {
      await _notif.showNow('¡Objetivo cumplido! 🎉',
          'Llegaste a tus $_goal pasos de hoy. ¡Excelente trabajo!');
    } catch (_) {}
  }
  Future<void> _loadProfile() async {
    try {
      final p = await context.read<AuthProvider>().api.getProfile();
      if (!mounted) return;
      setState(() {
        _age = p.age;
        _bmi = p.bmi;
        _weight = p.weightKg;
        _height = p.heightCm;
        _recSleepHours = _recommendedSleep(p.age);
      });
    } catch (_) {}
  }
  int _recommendedSleep(int? age) {
    if (age == null) return 8;
    if (age < 13) return 10;
    if (age < 18) return 9;
    if (age >= 65) return 7;
    return 8;
  }
  int _recommendedGoal(int? age, double? bmi) {
    int goal = 8000;
    if (bmi != null) {
      if (bmi >= 30) {
        goal = 11000;
      } else if (bmi >= 25) {
        goal = 10000;
      } else if (bmi < 18.5) {
        goal = 7000;
      }
    }
    if (age != null) {
      if (age >= 65) goal = (goal * 0.8).round();
      if (age < 13 && goal < 9000) goal = 9000;
    }
    return (goal / 500).round() * 500;
  }
  double get _strideM => _height != null ? _height! * 0.415 / 100 : 0.762;
  double get _distanceKm => _steps * _strideM / 1000;
  int get _calories =>
      (_steps * (_weight != null ? _weight! * 0.0005 : 0.04)).round();
  int get _activeMin => (_steps / 110).round();
  Future<void> _enable() async {
    final ok = await _health.requestPermission();
    if (!ok) {
      if (mounted) {
        showError(context, 'Permiso de actividad denegado. Actívalo en Ajustes.');
      }
      return;
    }
    try {
      await _notif.requestPermission();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('steps_enabled', true);
    await _startCounting();
  }
  Future<void> _editGoal() async {
    final ctrl = TextEditingController(text: _goal.toString());
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Objetivo de pasos diario'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'pasos'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(ctrl.text) ?? _goal),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (v != null && v > 0) {
      await _health.setGoal(v);
      setState(() {
        _goal = v;
        _congratsShown = false; 
      _goalCelebrated = false;
      });
    }
  }
  Future<bool> _ensureNotifPermission() async {
    final granted = await _notif.requestPermission();
    if (!granted && mounted) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Activa las notificaciones'),
          content: const Text(
              'Para recibir recordatorios y felicitaciones, permite las '
              'notificaciones de Circe en los ajustes del sistema.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ahora no')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Abrir ajustes')),
          ],
        ),
      );
      if (go == true) await _notif.openSettings();
    }
    return granted;
  }
  Future<void> _toggleGoal(bool v) async {
    setState(() => _remGoal = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rem_goal', v);
    if (v) {
      await _ensureNotifPermission();
      _maybeCongrats();
    }
  }
  Future<void> _toggleSleep(bool v) async {
    setState(() => _remSleep = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rem_sleep', v);
    try {
      if (v) {
        final ok = await _ensureNotifPermission();
        if (!ok) return;
        await _notif.requestBatteryExemption();
        await _notif.scheduleDaily(102, _sleepTime.hour, _sleepTime.minute,
            'Hora de descansar 🌙',
            'Tu cuerpo necesita ~$_recSleepHours h de sueño. Buenas noches.');
      } else {
        await _notif.cancel(102);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _remSleep = false);
        await prefs.setBool('rem_sleep', false);
        showError(context, 'No se pudo programar: $e');
      }
    }
  }
  Future<void> _pickSleepTime() async {
    final t = await showTimePicker(context: context, initialTime: _sleepTime);
    if (t == null) return;
    setState(() => _sleepTime = t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rem_sleep_t', '${t.hour}:${t.minute}');
    if (_remSleep) {
      try {
        await _notif.scheduleDaily(102, t.hour, t.minute, 'Hora de descansar 🌙',
            'Tu cuerpo necesita ~$_recSleepHours h de sueño. Buenas noches.');
      } catch (_) {}
    }
  }
  Future<void> _applyProfile() async {
    if (_age == null && _bmi == null) {
      showError(context,
          'Completa tu edad y peso/altura en tu perfil para personalizar.');
      return;
    }
    final goal = _recommendedGoal(_age, _bmi);
    final sleep = _recommendedSleep(_age);
    final bedHour = (7 - sleep + 24) % 24;
    final bedtime = TimeOfDay(hour: bedHour, minute: 0);
    await _health.setGoal(goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rem_sleep_t', '${bedtime.hour}:${bedtime.minute}');
    setState(() {
      _goal = goal;
      _recSleepHours = sleep;
      _sleepTime = bedtime;
      _congratsShown = false;
    });
    if (_remSleep) {
      try {
        await _notif.scheduleDaily(102, bedtime.hour, bedtime.minute,
            'Hora de descansar 🌙', 'Tu cuerpo necesita ~$sleep h de sueño.');
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Personalizado: $goal pasos · sueño $sleep h · dormir ${bedtime.format(context)}')));
    }
  }
  Future<void> _aiSuggestion() async {
    final api = context.read<AuthProvider>().api;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final reply = await api.suggest(
          'Hoy llevo $_steps pasos (objetivo $_goal), ~$_distanceKm km, '
          '$_calories kcal y $_activeMin min activo. Dame un consejo breve y '
          'motivador sobre mi actividad física de hoy.');
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: const [
              Icon(Icons.auto_awesome, color: AppColors.lavender),
              SizedBox(width: 8),
              Text('Sugerencia de Circe'),
            ]),
            content: Text(reply, style: const TextStyle(height: 1.5)),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Gracias'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showError(context, e);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!healthSupported) {
      return const PastelBackground(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'El contador de pasos está disponible en la app móvil de Circe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
        ),
      );
    }
    final pct = _goal > 0 ? (_steps / _goal).clamp(0.0, 1.0) : 0.0;
    return Stack(
      children: [
        _content(pct),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.04,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              AppColors.teal,
              AppColors.blue,
              AppColors.lavender,
              AppColors.rose,
              AppColors.purple,
            ],
          ),
        ),
      ],
    );
  }
  Widget _content(double pct) {
    return PastelBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GradientText('Actividad',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    width: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 190,
                          width: 190,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 14,
                            backgroundColor:
                                AppColors.lavenderSoft.withValues(alpha: 0.4),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.lavender),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_steps',
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            Text('de $_goal pasos',
                                style:
                                    const TextStyle(color: AppColors.inkSoft)),
                            const SizedBox(height: 4),
                            Text('${(pct * 100).round()}%',
                                style: const TextStyle(
                                    color: AppColors.lavender,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _metricsRow(),
                  const SizedBox(height: 16),
                  if (!_started)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _enable,
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Activar contador de pasos'),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _editGoal,
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Objetivo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _aiSuggestion,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Sugerencia IA'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _remindersCard(),
            const SizedBox(height: 16),
            _hourlyCard(),
            const SizedBox(height: 16),
            _historyCard(),
          ],
        ),
      ),
    );
  }
  Widget _hourlyCard() {
    final maxv = _hourly.fold<int>(0, (a, b) => a > b ? a : b);
    final peakHour = maxv > 0 ? _hourly.indexOf(maxv) : -1;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pasos por hora',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (peakHour >= 0)
                Text('Pico: ${peakHour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: maxv == 0
                ? const Center(
                    child: Text(
                        'Camina con la app abierta para ver tu actividad por hora',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13)))
                : BarChart(_hourlyChartData(maxv.toDouble())),
          ),
        ],
      ),
    );
  }
  BarChartData _hourlyChartData(double maxv) {
    final nowHour = DateTime.now().hour;
    return BarChartData(
      alignment: BarChartAlignment.spaceBetween,
      maxY: maxv * 1.15,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.purple,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${group.x.toString().padLeft(2, '0')}:00\n${rod.toY.round()} pasos',
            const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final h = value.toInt();
              if (h % 6 != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(h == 0 ? '0' : '${h}h',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 10)),
              );
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int h = 0; h < 24; h++)
          BarChartGroupData(x: h, barRods: [
            BarChartRodData(
              toY: _hourly[h].toDouble(),
              width: 6,
              borderRadius: BorderRadius.circular(3),
              color: h == nowHour ? AppColors.rose : AppColors.lavender,
            ),
          ]),
      ],
    );
  }
  Widget _metricsRow() {
    Widget item(IconData ic, Color c, String value, String label) => Expanded(
          child: Column(
            children: [
              Icon(ic, color: c, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Text(label,
                  style:
                      const TextStyle(color: AppColors.inkSoft, fontSize: 11)),
            ],
          ),
        );
    return Row(
      children: [
        item(Icons.straighten, AppColors.blue,
            '${_distanceKm.toStringAsFixed(2)} km', 'Distancia'),
        item(Icons.local_fire_department, AppColors.rose, '$_calories', 'kcal'),
        item(Icons.timer_outlined, AppColors.teal, '$_activeMin min', 'Activo'),
      ],
    );
  }
  Widget _remindersCard() {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Recordatorios y objetivos',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed: _applyProfile,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Ajustar a mi perfil'),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lavenderSoft.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.bedtime_outlined,
                  size: 16, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sueño recomendado: $_recSleepHours h por noche'
                  '${_age != null ? ' · ${_age} años' : ''}'
                  '${_bmi != null ? ' · IMC ${_bmi!.toStringAsFixed(1)}' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                ),
              ),
            ]),
          ),
          _reminderRow(
            icon: Icons.emoji_events_outlined,
            title: 'Felicitarme al cumplir mi objetivo',
            subtitle: 'Te avisamos cuando llegues a $_goal pasos',
            value: _remGoal,
            onToggle: _toggleGoal,
          ),
          const Divider(height: 8),
          _reminderRow(
            icon: Icons.bedtime,
            title: 'Recordatorio para dormir',
            value: _remSleep,
            onToggle: _toggleSleep,
            timeChip: _timeChip(_sleepTime, _pickSleepTime),
          ),
        ],
      ),
    );
  }
  Widget _timeChip(TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6E1F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text('Todos los días · ${time.format(context)}',
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.edit, size: 12, color: AppColors.inkSoft),
        ]),
      ),
    );
  }
  Widget _reminderRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onToggle,
    Widget? timeChip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lavender, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12)),
                ],
                if (timeChip != null) ...[
                  const SizedBox(height: 6),
                  timeChip,
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onToggle),
        ],
      ),
    );
  }
  Widget _historyCard() {
    final entries = _history.entries.toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Últimos 7 días',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(e.key.substring(5),
                        style: const TextStyle(color: AppColors.inkSoft)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _goal > 0 ? (e.value / _goal).clamp(0.0, 1.0) : 0,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEDE9F7),
                        valueColor: AlwaysStoppedAnimation(
                            e.value >= _goal ? AppColors.ok : AppColors.lavender),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56,
                    child: Text('${e.value}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (e.value >= _goal)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.check_circle,
                          color: AppColors.ok, size: 16),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
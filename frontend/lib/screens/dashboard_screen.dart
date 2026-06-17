import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_provider.dart';
import '../services/realtime_service.dart';
import '../theme.dart';
import '../widgets.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  final _rt = RealtimeService();
  List<Measurement> _measurements = [];
  String? _recommendation;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
    final auth = context.read<AuthProvider>();
    if (auth.api.token != null) {
      _rt.connect(auth.api.token!, _onMeasurement);
    }
  }
  @override
  void dispose() {
    _rt.disconnect();
    super.dispose();
  }
  void _onMeasurement(Measurement m) {
    setState(() => _measurements = [m, ..._measurements].take(50).toList());
  }
  Future<void> _load() async {
    final api = context.read<AuthProvider>().api;
    try {
      final data = await api.measurements(limit: 30);
      setState(() {
        _measurements = data;
        _loading = false;
      });
      api.recommendation().then((r) {
        if (mounted) setState(() => _recommendation = r);
      }).catchError((_) {});
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, e);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final latest = _measurements.isNotEmpty ? _measurements.first : null;
    final auth = context.watch<AuthProvider>();
    return PastelBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 760;
                    return isDesktop
                        ? _desktopBody(latest, auth)
                        : _mobileBody(latest, auth);
                  },
                ),
        ),
      ),
    );
  }
  Widget _mobileBody(Measurement? latest, AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hola 👋',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                GradientText(
                  auth.displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const CirceLogo(size: 46),
          ],
        ),
        const SizedBox(height: 20),
        if (latest != null && latest.isAlert) _AlertBanner(latest),
        if (latest != null && latest.isAlert) const SizedBox(height: 16),
        _vitalsGrid(latest),
        const SizedBox(height: 20),
        _chartCard(),
        const SizedBox(height: 20),
        _recommendationCard(),
        const SizedBox(height: 20),
        _historyCard(),
      ],
    );
  }
  Widget _desktopBody(Measurement? latest, AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _desktopHeader(auth),
              const SizedBox(height: 28),
              if (latest != null && latest.isAlert) ...[
                _AlertBanner(latest),
                const SizedBox(height: 22),
              ],
              _desktopVitals(latest)
                  .animate()
                  .fadeIn(duration: 450.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _desktopChartCard(),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _desktopOxygenGauge(latest)),
                              const SizedBox(width: 24),
                              Expanded(child: _desktopTempGauge(latest)),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 500.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _recommendationCard(),
                        const SizedBox(height: 24),
                        _desktopHistoryCard(),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 500.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  Widget _desktopHeader(AuthProvider auth) {
    final now = DateTime.now();
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
      'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final cap =
        '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hola 👋',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 15)),
            const SizedBox(height: 2),
            GradientText(
              auth.displayName,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE6F4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_rounded,
                  size: 17, color: AppColors.purple),
              const SizedBox(width: 10),
              Text(cap,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ],
          ),
        ),
      ],
    );
  }
  Widget _desktopVitals(Measurement? m) {
    final cards = [
      _DesktopVitalCard(
        title: 'Frecuencia cardíaca',
        value: m?.heartRate.toString() ?? '--',
        numericValue: m?.heartRate.toDouble(),
        unit: 'lpm',
        icon: Icons.monitor_heart_outlined,
        color: AppColors.rose,
      ),
      _DesktopVitalCard(
        title: 'Oxígeno (SpO₂)',
        value: m?.spo2.toString() ?? '--',
        numericValue: m?.spo2.toDouble(),
        unit: '%',
        icon: Icons.air_rounded,
        color: AppColors.primary,
      ),
      _DesktopVitalCard(
        title: 'Temperatura',
        value: m != null ? m.temperature.toStringAsFixed(1) : '--',
        numericValue: m?.temperature,
        decimals: 1,
        unit: '°C',
        icon: Icons.thermostat_outlined,
        color: AppColors.peach,
      ),
      _DesktopVitalCard(
        title: 'Estado',
        value: m?.status ?? '--',
        unit: '',
        icon: Icons.health_and_safety_outlined,
        color: m?.isAlert == true ? AppColors.danger : AppColors.ok,
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
  Widget _desktopChartCard() {
    final data = _measurements.reversed.toList();
    final avg = _measurements.isEmpty
        ? null
        : (_measurements.map((m) => m.heartRate).reduce((a, b) => a + b) /
                _measurements.length)
            .round();
    return SoftCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppColors.rose, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Tendencia · Frecuencia cardíaca',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              if (avg != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('Promedio  ',
                          style: TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                      Text('$avg',
                          style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const Text(' lpm',
                          style: TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: data.length < 2
                ? const Center(
                    child: Text('Aún no hay suficientes datos',
                        style: TextStyle(color: AppColors.inkSoft)))
                : LineChart(_chartData(data)),
          ),
        ],
      ),
    );
  }
  Widget _desktopHistoryCard() {
    final recent = _measurements.take(8).toList();
    final fmt = DateFormat('dd/MM HH:mm');
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded,
                    color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Historial reciente',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sin mediciones todavía',
                  style: TextStyle(color: AppColors.inkSoft)),
            ),
          for (final m in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: m.isAlert ? AppColors.danger : AppColors.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(fmt.format(m.recordedAt),
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 13)),
                  ),
                  Text(
                      '${m.heartRate} lpm · ${m.spo2}% · ${m.temperature.toStringAsFixed(1)}°',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _desktopOxygenGauge(Measurement? m) {
    final v = m?.spo2;
    final frac = v == null ? 0.0 : (v / 100).clamp(0.0, 1.0).toDouble();
    final color = (v != null && v < 92) ? AppColors.danger : AppColors.primary;
    final status = v == null
        ? 'Sin datos'
        : v < 92
            ? 'Bajo'
            : v < 95
                ? 'Aceptable'
                : 'Óptimo';
    return _GaugeCard(
      icon: Icons.air_rounded,
      iconColor: AppColors.primary,
      title: 'Oxígeno (SpO₂)',
      centerValue: v?.toString() ?? '--',
      centerUnit: '%',
      fraction: frac,
      color: color,
      status: status,
    );
  }
  Widget _desktopTempGauge(Measurement? m) {
    final t = m?.temperature;
    final frac =
        t == null ? 0.0 : ((t - 35) / 5).clamp(0.0, 1.0).toDouble();
    final color = t == null
        ? AppColors.inkSoft
        : t >= 37.8
            ? AppColors.danger
            : t >= 37.3
                ? AppColors.warn
                : const Color(0xFFEFA868);
    final status = t == null
        ? 'Sin datos'
        : t >= 37.8
            ? 'Fiebre'
            : t >= 37.3
                ? 'Elevada'
                : 'Normal';
    return _GaugeCard(
      icon: Icons.thermostat_outlined,
      iconColor: const Color(0xFFEFA868),
      title: 'Temperatura',
      centerValue: t != null ? t.toStringAsFixed(1) : '--',
      centerUnit: '°C',
      fraction: frac,
      color: color,
      status: status,
    );
  }
  Widget _vitalsGrid(Measurement? m) {
    final cards = [
      VitalCard(
        title: 'Frecuencia cardíaca',
        value: m?.heartRate.toString() ?? '--',
        numericValue: m?.heartRate.toDouble(),
        unit: 'lpm',
        icon: Icons.monitor_heart_outlined,
        color: AppColors.rose,
      ),
      VitalCard(
        title: 'Oxígeno (SpO₂)',
        value: m?.spo2.toString() ?? '--',
        numericValue: m?.spo2.toDouble(),
        unit: '%',
        icon: Icons.air_rounded,
        color: AppColors.primary,
      ),
      VitalCard(
        title: 'Temperatura',
        value: m != null ? m.temperature.toStringAsFixed(1) : '--',
        numericValue: m?.temperature,
        decimals: 1,
        unit: '°C',
        icon: Icons.thermostat_outlined,
        color: AppColors.peach,
      ),
      VitalCard(
        title: 'Estado',
        value: m?.status ?? '--',
        unit: '',
        icon: Icons.health_and_safety_outlined,
        color: m?.isAlert == true ? AppColors.danger : AppColors.ok,
      ),
    ];
    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 14),
              Expanded(child: b),
            ],
          ),
        );
    return Column(
      children: [
        row(cards[0], cards[1]),
        const SizedBox(height: 14),
        row(cards[2], cards[3]),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }
  Widget _chartCard() {
    final data = _measurements.reversed.toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tendencia · Frecuencia cardíaca',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: data.length < 2
                ? const Center(
                    child: Text('Aún no hay suficientes datos',
                        style: TextStyle(color: AppColors.inkSoft)))
                : LineChart(_chartData(data)),
          ),
        ],
      ),
    );
  }
  LineChartData _chartData(List<Measurement> data) {
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].heartRate.toDouble())
    ];
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primaryDark,
          getTooltipItems: (spots) => spots.map((s) {
            final m = data[s.x.toInt()];
            return LineTooltipItem(
              '${m.heartRate} lpm\n',
              const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              children: [
                TextSpan(
                  text: DateFormat('dd/MM HH:mm').format(m.recordedAt),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
        getTouchedSpotIndicator: (barData, indexes) => indexes
            .map((i) => TouchedSpotIndicatorData(
                  FlLine(color: AppColors.primary.withValues(alpha: 0.4)),
                  FlDotData(
                    getDotPainter: (s, _, b, __) => FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppColors.primaryDark),
                  ),
                ))
            .toList(),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: const Color(0xFFEDF1F9), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 20),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primaryDark,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.30),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _recommendationCard() {
    return SoftCard(
      color: AppColors.lavender.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recomendación inteligente',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _recommendation ?? 'Analizando tus datos...',
                  style: const TextStyle(color: AppColors.ink, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _historyCard() {
    final recent = _measurements.take(10).toList();
    final fmt = DateFormat('dd/MM HH:mm');
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial reciente',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sin mediciones todavía',
                  style: TextStyle(color: AppColors.inkSoft)),
            ),
          for (final m in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: m.isAlert ? AppColors.danger : AppColors.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(fmt.format(m.recordedAt),
                        style: const TextStyle(color: AppColors.inkSoft)),
                  ),
                  Text('${m.heartRate} lpm · ${m.spo2}% · ${m.temperature.toStringAsFixed(1)}°',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}
class _AlertBanner extends StatelessWidget {
  final Measurement m;
  const _AlertBanner(this.m);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.rose, AppColors.danger]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Alerta médica detectada',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Revisa tus signos. Ante síntomas, consulta a un médico.',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.015, duration: 1100.ms, curve: Curves.easeInOut);
  }
}
class _GaugeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String centerValue;
  final String centerUnit;
  final double fraction; 
  final Color color;
  final String status;
  const _GaugeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.centerValue,
    required this.centerUnit,
    required this.fraction,
    required this.color,
    required this.status,
  });
  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 52,
                    sections: [
                      PieChartSectionData(
                        value: f * 100,
                        color: color,
                        radius: 13,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - f) * 100,
                        color: color.withValues(alpha: 0.12),
                        radius: 13,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(centerValue,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    if (centerUnit.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(centerUnit,
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 13)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}
class _DesktopVitalCard extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double? numericValue;
  final int decimals;
  const _DesktopVitalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.numericValue,
    this.decimals = 0,
  });
  @override
  State<_DesktopVitalCard> createState() => _DesktopVitalCardState();
}
class _DesktopVitalCardState extends State<_DesktopVitalCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    const valueStyle = TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink);
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hover ? c.withValues(alpha: 0.35) : const Color(0xFFEFECF7),
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: _hover ? 0.22 : 0.10),
              blurRadius: _hover ? 30 : 20,
              offset: Offset(0, _hover ? 14 : 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: c, size: 24),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: widget.numericValue != null
                        ? AnimatedCounter(
                            value: widget.numericValue!,
                            decimals: widget.decimals,
                            style: valueStyle)
                        : Text(widget.value, maxLines: 1, style: valueStyle),
                  ),
                ),
                if (widget.unit.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(widget.unit,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 14)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
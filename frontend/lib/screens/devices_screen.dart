import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import 'device_settings_screen.dart';
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}
class _DevicesScreenState extends State<DevicesScreen> {
  List<Device> _devices = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    try {
      final d = await context.read<AuthProvider>().api.devices();
      if (mounted) setState(() {
        _devices = d;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, e);
      }
    }
  }
  Future<void> _pairDialog() async {
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vincular dispositivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Introduce el código que muestra el portal de tu monitor '
                '(ej. A1B2C3).'),
            const SizedBox(height: 16),
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Código'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vincular')),
        ],
      ),
    );
    if (ok == true && code.text.trim().isNotEmpty) {
      try {
        await context
            .read<AuthProvider>()
            .api
            .pairDevice(code.text.trim().toUpperCase());
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dispositivo vinculado ✅')));
        }
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ResponsiveCenter(
            maxWidth: 860,
            child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GradientText('Mis dispositivos',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Vincula y configura tu monitor biomédico',
                  style: TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_devices.isEmpty)
                _emptyState()
              else
                ..._devices.map(_deviceCard),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _pairDialog,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Vincular nuevo dispositivo'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
  Widget _emptyState() {
    return SoftCard(
      child: Column(
        children: const [
          Icon(Icons.sensors_off_rounded,
              size: 48, color: AppColors.inkSoft),
          SizedBox(height: 12),
          Text('No tienes dispositivos vinculados',
              style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text(
            'Enciende tu monitor, conéctate a su WiFi de configuración y usa el '
            'código de vinculación.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
        ],
      ),
    );
  }
  Widget _deviceCard(Device d) {
    final seen = d.lastSeen != null
        ? DateFormat('dd/MM HH:mm').format(d.lastSeen!)
        : 'nunca';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSettings(d),
        child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.sensors_rounded,
                      color: AppColors.ok),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${d.deviceUid} · modo ${d.mode}',
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'config') _openSettings(d);
                    if (v == 'unpair') _unpair(d);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'config', child: Text('Configurar')),
                    PopupMenuItem(
                        value: 'unpair', child: Text('Desvincular')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                Text('Última conexión: $seen',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
            if (d.smsNumbers != null && d.smsNumbers!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.sms_outlined,
                      size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('SMS a: ${d.smsNumbers}',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
  Future<void> _openSettings(Device d) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DeviceSettingsScreen(device: d)),
    );
    if (changed == true) await _load();
  }
  Future<void> _unpair(Device d) async {
    try {
      await context.read<AuthProvider>().api.unpairDevice(d.id);
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
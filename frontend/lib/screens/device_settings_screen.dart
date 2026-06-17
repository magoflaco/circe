import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_provider.dart';
import '../services/contacts_service.dart';
import '../theme.dart';
import '../widgets.dart';
class DeviceSettingsScreen extends StatefulWidget {
  final Device device;
  const DeviceSettingsScreen({super.key, required this.device});
  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}
class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  late final TextEditingController _name;
  late String _mode;
  late List<TextEditingController> _numbers;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.device.name);
    _mode = widget.device.mode;
    final existing = (widget.device.smsNumbers ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _numbers = (existing.isEmpty ? [''] : existing)
        .map((n) => TextEditingController(text: n))
        .toList();
  }
  @override
  void dispose() {
    _name.dispose();
    for (final c in _numbers) {
      c.dispose();
    }
    super.dispose();
  }
  void _addNumber([String value = '']) {
    setState(() => _numbers.add(TextEditingController(text: value)));
  }
  void _removeNumber(int i) {
    setState(() {
      _numbers[i].dispose();
      _numbers.removeAt(i);
      if (_numbers.isEmpty) _numbers.add(TextEditingController());
    });
  }
  Future<void> _importContacts() async {
    try {
      final phones = await pickContactNumbers();
      if (phones.isEmpty) return;
      if (_numbers.length == 1 && _numbers.first.text.trim().isEmpty) {
        _numbers.first.text = phones.first;
        for (final p in phones.skip(1)) {
          _addNumber(p);
        }
      } else {
        for (final p in phones) {
          _addNumber(p);
        }
      }
      setState(() {});
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
  Future<void> _save() async {
    final numbers = _numbers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().api.configureDevice(
            widget.device.id,
            name: _name.text.trim(),
            mode: _mode,
            smsNumbers: numbers,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispositivo actualizado ✅')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar dispositivo')),
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const CirceLogo(size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.device.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text(widget.device.deviceUid,
                                    style: const TextStyle(
                                        color: AppColors.inkSoft, fontSize: 12)),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                              labelText: 'Nombre del dispositivo',
                              prefixIcon: Icon(Icons.badge_outlined)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Modo de conexión',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSoft,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'wifi',
                                label: Text('WiFi'),
                                icon: Icon(Icons.wifi)),
                            ButtonSegment(
                                value: 'gprs',
                                label: Text('GPRS'),
                                icon: Icon(Icons.signal_cellular_alt)),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (s) =>
                              setState(() => _mode = s.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sms_outlined,
                                color: AppColors.teal, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Números para alertas SMS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'El módulo enviará un SMS a estos números ante cada '
                          'alerta. Puedes añadir varios.',
                          style:
                              TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 0; i < _numbers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _numbers[i],
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: '+593999999999',
                                      prefixIcon:
                                          const Icon(Icons.phone_outlined),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeNumber(i),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _addNumber(),
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir número'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side:
                                    const BorderSide(color: AppColors.lavender),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            if (!kIsWeb && contactsSupported)
                              OutlinedButton.icon(
                                onPressed: _importContacts,
                                icon: const Icon(Icons.contacts_outlined),
                                label: const Text('Desde contactos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.teal,
                                  side: const BorderSide(color: AppColors.teal),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
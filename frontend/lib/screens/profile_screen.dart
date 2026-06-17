import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import 'legal_screens.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  HealthProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _conditions = TextEditingController();
  final _medications = TextEditingController();
  final _emergency = TextEditingController();
  String _gender = 'unspecified';
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    try {
      final p = await context.read<AuthProvider>().api.getProfile();
      setState(() {
        _profile = p;
        _age.text = p.age?.toString() ?? '';
        _weight.text = p.weightKg?.toString() ?? '';
        _height.text = p.heightCm?.toString() ?? '';
        _conditions.text = p.conditions ?? '';
        _medications.text = p.medications ?? '';
        _emergency.text = p.emergencyContact ?? '';
        _gender = p.gender ?? 'unspecified';
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, e);
      }
    }
  }
  Future<void> _save() async {
    setState(() => _saving = true);
    final p = HealthProfile(
      age: int.tryParse(_age.text),
      gender: _gender,
      weightKg: double.tryParse(_weight.text),
      heightCm: double.tryParse(_height.text),
      conditions: _conditions.text,
      medications: _medications.text,
      emergencyContact: _emergency.text,
    );
    try {
      final updated = await context.read<AuthProvider>().api.updateProfile(p);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil guardado ✅')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return PastelBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveCenter(
                maxWidth: 860,
                child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientText('Mi perfil',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      if (_profile?.bmi != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('IMC ${_profile!.bmi}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(auth.email ?? '',
                      style: const TextStyle(color: AppColors.inkSoft)),
                  const SizedBox(height: 20),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Datos de salud',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _age,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Edad'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                    labelText: 'Género'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'male', child: Text('Masculino')),
                                  DropdownMenuItem(
                                      value: 'female', child: Text('Femenino')),
                                  DropdownMenuItem(
                                      value: 'other', child: Text('Otro')),
                                  DropdownMenuItem(
                                      value: 'unspecified',
                                      child: Text('Sin especificar')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _gender = v ?? 'unspecified'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weight,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Peso (kg)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _height,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Altura (cm)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _conditions,
                          decoration: const InputDecoration(
                              labelText: 'Condiciones médicas'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _medications,
                          decoration: const InputDecoration(
                              labelText: 'Medicación actual'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emergency,
                          decoration: const InputDecoration(
                              labelText: 'Contacto de emergencia'),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Guardar perfil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline,
                              color: AppColors.primaryDark),
                          title: const Text('Acerca de Circe'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined,
                              color: AppColors.primaryDark),
                          title: const Text('Privacidad y manejo de datos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PrivacyScreen()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded,
                              color: AppColors.danger),
                          title: const Text('Cerrar sesión',
                              style: TextStyle(color: AppColors.danger)),
                          onTap: () =>
                              context.read<AuthProvider>().logout(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '⚕️ Este sistema es de apoyo y carácter educativo. No '
                    'sustituye el diagnóstico ni la atención de un profesional '
                    'de la salud.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
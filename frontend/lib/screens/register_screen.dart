import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import 'legal_screens.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _accepted = false;
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      showError(context, 'Debes aceptar los Términos y la Política de Privacidad');
      return;
    }
    setState(() => _loading = true);
    try {
      await context
          .read<AuthProvider>()
          .register(_email.text.trim(), _password.text, _name.text.trim());
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SoftCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CirceLogo(size: 44),
                            const SizedBox(width: 12),
                            GradientText('Únete a Circe',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => v != null && v.trim().length >= 2
                              ? null
                              : 'Ingresa tu nombre',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline)),
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Email inválido',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Contraseña (mín. 8)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v != null && v.length >= 8
                              ? null
                              : 'Mínimo 8 caracteres',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password2,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                              labelText: 'Repetir contraseña',
                              prefixIcon: Icon(Icons.lock_reset_outlined)),
                          validator: (v) =>
                              v == _password.text ? null : 'Las contraseñas no coinciden',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _accepted,
                              onChanged: (v) =>
                                  setState(() => _accepted = v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _termsText(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Crear cuenta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _termsText(BuildContext context) {
    TextSpan link(String text, Widget page) => TextSpan(
          text: text,
          style: const TextStyle(
              color: AppColors.primaryDark, fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()
            ..onTap = () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => page)),
        );
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.4),
        children: [
          const TextSpan(text: 'He leído y acepto los '),
          link('Términos de Uso', const TermsScreen()),
          const TextSpan(text: ' y la '),
          link('Política de Privacidad', const PrivacyScreen()),
          const TextSpan(text: ' de Circe.'),
        ],
      ),
    );
  }
}
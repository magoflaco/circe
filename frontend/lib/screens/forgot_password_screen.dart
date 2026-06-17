import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }
  Future<void> _sendCode() async {
    if (!_email.text.contains('@')) {
      showError(context, 'Ingresa un email válido');
      return;
    }
    setState(() => _loading = true);
    try {
      final msg = await context.read<AuthProvider>().forgotPassword(_email.text.trim());
      if (mounted) {
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _reset() async {
    if (_code.text.trim().length < 6 || _password.text.length < 8) {
      showError(context, 'Revisa el código y la nueva contraseña (mín. 8)');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().resetPassword(
          _email.text.trim(), _code.text.trim(), _password.text);
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Contraseña actualizada. ¡Bienvenido de nuevo!')));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const CirceLogo(size: 44),
                        const SizedBox(width: 12),
                        GradientText('Recuperar acceso',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 16),
                      Text(
                        _codeSent
                            ? 'Revisa tu correo e introduce el código junto a tu nueva contraseña.'
                            : 'Te enviaremos un código de 6 dígitos a tu correo.',
                        style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _email,
                        enabled: !_codeSent,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline)),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              counterText: '',
                              labelText: 'Código de 6 dígitos',
                              prefixIcon: Icon(Icons.pin_outlined)),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña (mín. 8)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : (_codeSent ? _reset : _sendCode),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_codeSent
                                  ? 'Cambiar contraseña'
                                  : 'Enviar código'),
                        ),
                      ),
                      if (_codeSent)
                        Center(
                          child: TextButton(
                            onPressed: _loading ? null : _sendCode,
                            child: const Text('Reenviar código'),
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
    );
  }
}
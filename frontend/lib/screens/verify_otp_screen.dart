import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
class VerifyOtpScreen extends StatefulWidget {
  final String? email;
  const VerifyOtpScreen({super.key, this.email});
  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}
class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }
  Future<void> _verify() async {
    if (_code.text.trim().length < 6) {
      showError(context, 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().verifyOtp(_code.text.trim());
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final msg = await context.read<AuthProvider>().resendCode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg.isEmpty ? 'Código reenviado' : msg)));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? context.watch<AuthProvider>().email ?? '';
    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const CirceLogo(size: 72),
                    const SizedBox(height: 20),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText('Verifica tu correo',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                            'Enviamos un código de 6 dígitos a $email. '
                            'Introdúcelo para activar tu cuenta.',
                            style: const TextStyle(
                                color: AppColors.inkSoft, height: 1.4),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 14),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                                counterText: '', hintText: '••••••'),
                            onSubmitted: (_) => _verify(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _verify,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Verificar cuenta'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _resending ? null : _resend,
                              child: Text(_resending
                                  ? 'Enviando...'
                                  : 'Reenviar código'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => context.read<AuthProvider>().logout(),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Usar otra cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
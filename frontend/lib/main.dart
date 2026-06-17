import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'services/auth_provider.dart';
import 'services/notifications_service.dart';
import 'screens/intro_screen.dart';
import 'screens/landing_page.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/verify_otp_screen.dart';
import 'theme.dart';
import 'widgets.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationsService().init().catchError((_) {});
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..bootstrap(),
      child: const CirceApp(),
    ),
  );
}
class CirceApp extends StatelessWidget {
  const CirceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _Gate(),
    );
  }
}
class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}
class _GateState extends State<_Gate> {
  bool _introSeen = false;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) return const _Splash();
    if (!auth.isAuthenticated) {
      if (kIsWeb) return const LandingPage();
      if (!_introSeen) {
        return IntroScreen(onStart: () => setState(() => _introSeen = true));
      }
      return const LoginScreen();
    }
    if (!auth.isVerified) return const VerifyOtpScreen();
    return const HomeShell();
  }
}
class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PastelBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CirceLogo(size: 96)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                      begin: 0.92,
                      end: 1.08,
                      duration: 900.ms,
                      curve: Curves.easeInOut),
              const SizedBox(height: 24),
              GradientText('Circe',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
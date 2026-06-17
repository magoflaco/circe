import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets.dart';
import 'legal_screens.dart';
import 'login_screen.dart';
import 'register_screen.dart';
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}
class _LandingPageState extends State<LandingPage> {
  bool _showInstallBar = true;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w >= 900;
    final mobile = w < 760;
    return Scaffold(
      body: PastelBackground(
        child: SingleChildScrollView(
          child: Column(
              children: [
                if (mobile && _showInstallBar)
                  _InstallBar(onClose: () => setState(() => _showInstallBar = false)),
                const _NavBar(),
                _Hero(wide: wide),
                const SizedBox(height: 30),
                _Features(wide: wide),
                const SizedBox(height: 40),
                _HowItWorks(wide: wide),
                const SizedBox(height: 40),
                _InstallApp(wide: wide),
                const SizedBox(height: 40),
                const _AboutTeaser(),
                const SizedBox(height: 30),
                const _Footer(),
              ],
            ),
          ),
        ),
    );
  }
}
void _go(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
EdgeInsets _pad(BuildContext c) {
  final w = MediaQuery.of(c).size.width;
  final h = w > 1100 ? (w - 1100) / 2 : 24.0;
  return EdgeInsets.symmetric(horizontal: h);
}
class _InstallBar extends StatelessWidget {
  final VoidCallback onClose;
  const _InstallBar({required this.onClose});
  Future<void> _download() async {
    final uri = Uri.parse(AppConfig.apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.phone_iphone, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Instala la app de Circe para una mejor experiencia',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          TextButton(
            onPressed: _download,
            style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: const Text('Instalar'),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
class _NavBar extends StatelessWidget {
  const _NavBar();
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 760;
    return Container(
      padding: _pad(context).add(const EdgeInsets.symmetric(vertical: 16)),
      child: Row(
        children: [
          const CirceLogo(size: 42),
          const SizedBox(width: 12),
          GradientText('Circe',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (wide) ...[
            TextButton(
                onPressed: () => _go(context, const AboutScreen()),
                child: const Text('Acerca de')),
            const SizedBox(width: 4),
            TextButton(
                onPressed: () => _go(context, const LoginScreen()),
                child: const Text('Iniciar sesión')),
            const SizedBox(width: 10),
          ],
          FilledButton(
            onPressed: () => _go(context, const RegisterScreen()),
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    );
  }
}
class _Hero extends StatelessWidget {
  final bool wide;
  const _Hero({required this.wide});
  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.lavenderSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text('Monitoreo biomédico inteligente · IoT + IA',
              style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        const SizedBox(height: 20),
        GradientText(
          'Tu salud, guiada\ncon cuidado',
          align: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
              fontSize: wide ? 52 : 36,
              height: 1.1,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Circe supervisa tu frecuencia cardíaca, oxígeno y temperatura en '
            'tiempo real. Recibe alertas inmediatas por SMS y recomendaciones '
            'personalizadas con inteligencia artificial.',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
                color: AppColors.inkSoft, fontSize: 16, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () => _go(context, const RegisterScreen()),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 18)),
              child: const Text('Empieza gratis'),
            ),
            OutlinedButton(
              onPressed: () => _go(context, const LoginScreen()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.lavender),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
    final art = Container(
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.glow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(CirceBrand.banner,
          fit: BoxFit.cover, filterQuality: FilterQuality.high),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
        begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
    return Padding(
      padding: _pad(context).add(const EdgeInsets.symmetric(vertical: 30)),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: text),
                const SizedBox(width: 40),
                Expanded(child: Center(child: art)),
              ],
            )
          : Column(children: [text, const SizedBox(height: 34), art]),
    );
  }
}
class _Features extends StatelessWidget {
  final bool wide;
  const _Features({required this.wide});
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.monitor_heart_outlined, 'Tiempo real',
          'Visualiza tus signos vitales al instante con gráficos interactivos.',
          AppColors.rose),
      (Icons.sms_outlined, 'Alertas por SMS',
          'El módulo envía un SMS de alerta ante cualquier anomalía, sin depender de internet.',
          AppColors.teal),
      (Icons.auto_awesome, 'IA que te entiende',
          'Recomendaciones y un asistente de salud personalizados según tu perfil.',
          AppColors.lavender),
      (Icons.lock_outline, 'Privacidad real',
          'Tus datos son tuyos. Cifrado, sin rastreo y eliminables cuando quieras.',
          AppColors.blue),
    ];
    return Padding(
      padding: _pad(context),
      child: Column(
        children: [
          GradientText('Todo lo que necesitas para cuidarte',
              align: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: [
              for (final it in items)
                SizedBox(
                  width: wide ? 250 : 320,
                  child: _FeatureCard(
                      icon: it.$1,
                      title: it.$2,
                      body: it.$3,
                      color: it.$4),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _FeatureCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: AppColors.inkSoft, height: 1.5, fontSize: 13.5)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
class _HowItWorks extends StatelessWidget {
  final bool wide;
  const _HowItWorks({required this.wide});
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Enciende tu módulo Circe',
          'Colócate el sensor. El dispositivo se conecta por WiFi o red móvil.'),
      ('2', 'Vincula tu cuenta',
          'Introduce el código de vinculación en la app para enlazar el módulo.'),
      ('3', 'Monitorea y recibe avisos',
          'Mira tus signos en tiempo real y recibe alertas y consejos de IA.'),
    ];
    return Container(
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.55),
      padding: _pad(context).add(const EdgeInsets.symmetric(vertical: 44)),
      child: Column(
        children: [
          GradientText('Cómo funciona',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              for (final s in steps)
                SizedBox(
                  width: wide ? 280 : 320,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(s.$1,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(s.$3,
                                style: const TextStyle(
                                    color: AppColors.inkSoft,
                                    height: 1.5,
                                    fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
class _InstallApp extends StatelessWidget {
  final bool wide;
  const _InstallApp({required this.wide});
  Future<void> _download() async {
    final uri = Uri.parse(AppConfig.apkUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  @override
  Widget build(BuildContext context) {
    final content = [
      Column(
        crossAxisAlignment:
            wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          GradientText('Llévala en tu bolsillo',
              align: wide ? TextAlign.left : TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              'Instala Circe en tu Android para monitoreo y alertas donde estés. '
              'Escanea el código QR o descarga el APK directamente.',
              textAlign: wide ? TextAlign.left : TextAlign.center,
              style: const TextStyle(
                  color: AppColors.inkSoft, height: 1.6, fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.android),
            label: const Text('Descargar APK'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softShadow),
        child: Column(
          children: [
            QrImageView(
              data: AppConfig.siteUrl,
              size: 150,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle, color: AppColors.purple),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            const Text('Escanéame',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
          ],
        ),
      ),
    ];
    return Padding(
      padding: _pad(context),
      child: SoftCard(
        padding: const EdgeInsets.all(34),
        child: wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: content[0]),
                  const SizedBox(width: 30),
                  content[1],
                ],
              )
            : Column(children: [content[0], const SizedBox(height: 26), content[1]]),
      ),
    );
  }
}
class _AboutTeaser extends StatelessWidget {
  const _AboutTeaser();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pad(context),
      child: Center(
        child: Column(
          children: [
            GradientText('Hecho con propósito',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: const Text(
                'Circe nació como un proyecto académico y de investigación para hacer '
                'el monitoreo preventivo de la salud accesible para todos. Conoce al '
                'equipo y la tecnología detrás del sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _go(context, const AboutScreen()),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Conoce al equipo'),
            ),
          ],
        ),
      ),
    );
  }
}
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2E2A3F),
      padding: _pad(context).add(const EdgeInsets.symmetric(vertical: 36)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CirceLogo(size: 38, shadow: false),
              const SizedBox(width: 10),
              const Text('Circe',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _FooterLink('Acerca de', () => _go(context, const AboutScreen())),
              _FooterLink(
                  'Términos', () => _go(context, const TermsScreen())),
              _FooterLink(
                  'Privacidad', () => _go(context, const PrivacyScreen())),
              _FooterLink('GitHub', () async {
                final uri = Uri.parse('https://github.com/magoflaco/circe');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }),
              _FooterLink(
                  'Iniciar sesión', () => _go(context, const LoginScreen())),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Sistema Inteligente de Monitoreo Biomédico\n'
            'Instituto Superior Universitario Bolivariano de Tecnología (ITB) · '
            'Guayaquil, Ecuador',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 8),
          const Text(
              '© 2026 Circe · S. Moreira · G. Chaviano · N. Valencia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink(this.text, this.onTap);
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}
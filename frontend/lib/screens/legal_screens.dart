import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';
import '../theme.dart';
import '../widgets.dart';
class _LegalScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _LegalScaffold(
      {required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PastelBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      const CirceLogo(size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GradientText(title,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w800)),
                            Text(subtitle,
                                style: const TextStyle(color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...children,
                  const SizedBox(height: 30),
                  const _LegalFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class LegalSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const LegalSection(
      {super.key, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.lavender, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(
                    color: AppColors.ink, height: 1.55, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Divider(),
        SizedBox(height: 10),
        Text('Circe · Sistema Inteligente de Monitoreo Biomédico',
            style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(
            'Instituto Superior Universitario Bolivariano de Tecnología (ITB) · '
            'Guayaquil, Ecuador',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
        SizedBox(height: 8),
        Text('Última actualización: junio 2026',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
      ],
    );
  }
}
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Términos de Uso',
      subtitle: 'Condiciones que aceptas al usar Circe',
      children: [
        LegalSection(
          icon: Icons.handshake_outlined,
          title: '1. Aceptación',
          body:
              'Al crear una cuenta y usar Circe aceptas estos Términos de Uso y la '
              'Política de Privacidad. Si no estás de acuerdo, por favor no utilices '
              'el servicio.',
        ),
        LegalSection(
          icon: Icons.favorite_border,
          title: '2. Qué es Circe',
          body:
              'Circe es una plataforma de monitoreo de signos vitales (frecuencia '
              'cardíaca, oxígeno en sangre y temperatura) basada en un dispositivo '
              'IoT y una aplicación web/móvil. Ofrece visualización en tiempo real, '
              'alertas y recomendaciones generadas con inteligencia artificial.',
        ),
        LegalSection(
          icon: Icons.medical_information_outlined,
          title: '3. Descargo médico (importante)',
          body:
              'Circe es una herramienta de apoyo y carácter educativo. NO es un '
              'dispositivo médico certificado ni sustituye el diagnóstico, tratamiento '
              'o criterio de un profesional de la salud. Las mediciones y las '
              'recomendaciones de IA son orientativas y pueden contener errores. Ante '
              'cualquier síntoma o emergencia, acude a un médico o a los servicios de '
              'emergencia.',
        ),
        LegalSection(
          icon: Icons.verified_user_outlined,
          title: '4. Uso responsable',
          body:
              'Te comprometes a usar Circe de forma lícita, a no intentar vulnerar la '
              'seguridad del sistema, y a proporcionar información veraz en tu perfil. '
              'Eres responsable de mantener la confidencialidad de tus credenciales.',
        ),
        LegalSection(
          icon: Icons.gpp_maybe_outlined,
          title: '5. Limitación de responsabilidad',
          body:
              'Circe se ofrece "tal cual", sin garantías de disponibilidad ininterrumpida '
              'ni exactitud absoluta. En la máxima medida permitida por la ley, el equipo '
              'de Circe no será responsable por daños derivados del uso o la imposibilidad '
              'de uso del servicio.',
        ),
        LegalSection(
          icon: Icons.update,
          title: '6. Cambios',
          body:
              'Podemos actualizar estos términos para reflejar mejoras del servicio o '
              'requisitos legales. Te notificaremos los cambios relevantes dentro de la '
              'aplicación.',
        ),
      ],
    );
  }
}
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Política de Privacidad',
      subtitle: 'Cómo tratamos y protegemos tus datos',
      children: [
        const LegalSection(
          icon: Icons.dataset_outlined,
          title: 'Qué datos recopilamos',
          body:
              '• Datos de cuenta: nombre y correo electrónico.\n'
              '• Perfil de salud que tú introduces: edad, género, peso, altura, '
              'condiciones y medicación.\n'
              '• Mediciones de signos vitales enviadas por tu dispositivo: frecuencia '
              'cardíaca, oxígeno (SpO₂) y temperatura, con su fecha y hora.\n'
              '• Conversaciones con el asistente de IA.',
        ),
        const LegalSection(
          icon: Icons.flag_outlined,
          title: 'Para qué los usamos',
          body:
              'Usamos tus datos exclusivamente para prestarte el servicio: mostrar tu '
              'panel en tiempo real, generar alertas y elaborar recomendaciones '
              'personalizadas con IA. No vendemos ni cedemos tus datos a terceros con '
              'fines comerciales ni publicitarios.',
        ),
        const LegalSection(
          icon: Icons.cookie_outlined,
          title: 'Cookies y almacenamiento',
          body:
              'En la versión web usamos almacenamiento local del navegador únicamente '
              'para mantener tu sesión iniciada (un token de acceso). No utilizamos '
              'cookies de rastreo, analítica invasiva ni publicidad de terceros.',
        ),
        const LegalSection(
          icon: Icons.lock_outline,
          title: 'Seguridad',
          body:
              'Las contraseñas se almacenan cifradas (hash bcrypt) y la comunicación '
              'viaja sobre HTTPS. Cada dispositivo se autentica con su propia clave de '
              'API. El acceso a tus datos requiere tu sesión autenticada.',
        ),
        const LegalSection(
          icon: Icons.schedule_outlined,
          title: 'Conservación',
          body:
              'Conservamos tus datos mientras tu cuenta esté activa. Puedes solicitar '
              'su eliminación en cualquier momento desde la app.',
        ),
        const LegalSection(
          icon: Icons.verified_user_outlined,
          title: 'Tus derechos',
          body:
              'Puedes acceder y actualizar tu perfil cuando quieras, y solicitar la '
              'eliminación permanente de todos tus datos (perfil, mediciones, alertas y '
              'conversaciones) con un solo toque. Esta acción es irreversible.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SoftCard(
            color: AppColors.roseSoft.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eliminar mis datos',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.danger)),
                const SizedBox(height: 8),
                const Text(
                  'Solicita la eliminación permanente de toda tu información. No se '
                  'puede deshacer.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Solicitar eliminación de datos'),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inicia sesión para gestionar tus datos.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar todos tus datos?'),
        content: const Text(
            'Se borrarán tu perfil, mediciones, alertas y conversaciones de forma '
            'permanente. Tus dispositivos quedarán liberados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        final msg = await auth.api.deleteMyData();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          await auth.logout();
        }
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }
  }
}
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _LegalScaffold(
      title: 'Acerca de Circe',
      subtitle: 'El proyecto y su equipo',
      children: [
        const LegalSection(
          icon: Icons.auto_awesome,
          title: 'El proyecto',
          body:
              'Circe es un sistema inteligente de monitoreo de salud en tiempo real '
              'basado en el Internet de las Cosas (IoT). Integra sensores biomédicos '
              'y un microcontrolador ESP32 con comunicación WiFi/GSM para supervisar '
              'signos vitales, generar alertas automáticas por SMS y ofrecer '
              'recomendaciones con inteligencia artificial. Nace como una alternativa '
              'accesible y de bajo costo para el monitoreo preventivo de la salud.',
        ),
        const LegalSection(
          icon: Icons.sensors,
          title: 'Cómo funciona',
          body:
              'El módulo Circe mide frecuencia cardíaca y oxígeno (MAX30102) y '
              'temperatura corporal (MLX90614). Los datos se envían al servidor y se '
              'muestran en tu panel en tiempo real. Si se detecta una anomalía, el '
              'módulo envía un SMS de alerta y la app te avisa al instante.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.groups_outlined, color: AppColors.lavender),
                  SizedBox(width: 10),
                  Text('Autores',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
                const SizedBox(height: 14),
                const _Author('Stiven Yiovanny Moreira Villafuerte',
                    'symoreira@itb.edu.ec', '0009-0000-4217-084X'),
                const _Author('Gabriel Chaviano Díaz', 'gchaviano@itb.edu.ec',
                    '0009-0002-7800-0556'),
                const _Author('Nohely Scarlett Valencia Panchana',
                    'nsvalencia@itb.edu.ec', '0009-0004-7828-483X'),
                const SizedBox(height: 16),
                const Text(
                  'Carrera de Tecnologías de la Información · Instituto Superior '
                  'Universitario Bolivariano de Tecnología (ITB) · Guayaquil, '
                  'Ecuador. Base de la ponencia IEEE sobre monitoreo inteligente '
                  'de signos vitales.',
                  style: TextStyle(
                      color: AppColors.inkSoft, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _open('https://github.com/magoflaco/circe'),
                  icon: const Icon(Icons.code),
                  label: const Text('Código fuente en GitHub'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    side: const BorderSide(color: AppColors.lavender),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
class _Author extends StatelessWidget {
  final String name;
  final String email;
  final String orcid;
  const _Author(this.name, this.email, this.orcid);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                gradient: AppColors.brandGradient, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$email · ORCID $orcid',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
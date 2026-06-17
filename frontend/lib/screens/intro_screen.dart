import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';
import '../widgets.dart';
class IntroScreen extends StatefulWidget {
  final VoidCallback onStart;
  const IntroScreen({super.key, required this.onStart});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}
class _IntroScreenState extends State<IntroScreen> {
  VideoPlayerController? _controller;
  bool _frozen = false;
  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.asset(CirceBrand.introVideo);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(0);
      c.play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _frozen = true);
    });
    c.addListener(_checkEnd);
  }
  void _checkEnd() {
    final v = _controller?.value;
    if (v == null || !v.isInitialized || _frozen) return;
    if (v.position >= v.duration && v.duration > Duration.zero) {
      setState(() => _frozen = true);
    }
  }
  @override
  void dispose() {
    _controller?.removeListener(_checkEnd);
    _controller?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _frozen ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              child: Image.asset(CirceBrand.introLastFrame,
                  fit: BoxFit.cover, filterQuality: FilterQuality.high),
            ),
          ),
          if (_frozen)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1700),
              curve: Curves.easeInOut,
              builder: (context, t, _) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7 * t, sigmaY: 7 * t),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bg.withValues(alpha: 0.10 * t),
                        AppColors.bg.withValues(alpha: 0.55 * t),
                        AppColors.bg.withValues(alpha: 0.92 * t),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_frozen) _content(context),
        ],
      ),
    );
  }
  Widget _content(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const CirceLogo(size: 64)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 18),
            GradientText('Circe',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w800))
                .animate()
                .fadeIn(delay: 150.ms, duration: 600.ms),
            const SizedBox(height: 10),
            const Text(
              'Tu salud, guiada con cuidado.\n'
              'Monitorea tu frecuencia cardíaca, oxígeno y temperatura en tiempo '
              'real. Recibe alertas inmediatas y recomendaciones con inteligencia '
              'artificial, siempre contigo.',
              style: TextStyle(
                  color: AppColors.ink, fontSize: 15.5, height: 1.6),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 700.ms)
                .slideY(begin: 0.15, end: 0),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.onStart,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 18)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Empezar'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 650.ms, duration: 600.ms).slideX(
                begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
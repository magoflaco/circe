import 'package:flutter/material.dart';
import 'theme.dart';
class PastelBackground extends StatelessWidget {
  final Widget child;
  const PastelBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBFAF4), 
            Color(0xFFEAF6F2), 
            Color(0xFFEDF0FF), 
            Color(0xFFF6ECF7), 
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}
class CirceLogo extends StatelessWidget {
  final double size;
  final bool shadow;
  const CirceLogo({super.key, this.size = 72, this.shadow = true});
  @override
  Widget build(BuildContext context) {
    final px = (size * 3).clamp(144, 600).round();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: shadow ? AppTheme.glow : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        CirceBrand.logo,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        cacheWidth: px,
        cacheHeight: px,
      ),
    );
  }
}
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? align;
  const GradientText(this.text,
      {super.key,
      required this.style,
      this.gradient = AppColors.titleGradient,
      this.align});
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => gradient.createShader(b),
      blendMode: BlendMode.srcIn,
      child: Text(text, textAlign: align, style: style),
    );
  }
}
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 880});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}
class AnimatedCounter extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle style;
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
  });
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.toStringAsFixed(decimals), style: style),
    );
  }
}
class VitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double? numericValue;
  final int decimals;
  const VitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.numericValue,
    this.decimals = 0,
  });
  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
        fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink);
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: numericValue != null
                      ? AnimatedCounter(
                          value: numericValue!,
                          decimals: decimals,
                          style: valueStyle)
                      : Text(value, maxLines: 1, style: valueStyle),
                ),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
class MarkdownText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double height;
  const MarkdownText(this.text,
      {super.key,
      required this.color,
      this.fontSize = 14.5,
      this.height = 1.45});
  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: color, fontSize: fontSize, height: height);
    final bullet = RegExp(r'^\s*[\*\-]\s+');
    final numbered = RegExp(r'^\s*(\d+)\.\s+');
    final heading = RegExp(r'^\s*(#{1,6})\s+');
    final children = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(SizedBox(height: fontSize * 0.55));
        continue;
      }
      if (bullet.hasMatch(line)) {
        children.add(_row('•', line.replaceFirst(bullet, ''), base));
      } else if (numbered.hasMatch(line)) {
        final m = numbered.firstMatch(line)!;
        children.add(_row('${m.group(1)}.', line.replaceFirst(numbered, ''),
            base));
      } else if (heading.hasMatch(line)) {
        final content = line.replaceFirst(heading, '');
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
              text: TextSpan(
                  children: _mdInline(content,
                      base.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize + 1.5)))),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: RichText(text: TextSpan(children: _mdInline(line, base))),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
  Widget _row(String marker, String content, TextStyle base) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(marker,
                style: base.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: RichText(text: TextSpan(children: _mdInline(content, base))),
          ),
        ],
      ),
    );
  }
}
List<InlineSpan> _mdInline(String s, TextStyle base) {
  final spans = <InlineSpan>[];
  final bold = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
  int idx = 0;
  for (final m in bold.allMatches(s)) {
    if (m.start > idx) spans.addAll(_mdItalic(s.substring(idx, m.start), base));
    final content = m.group(1) ?? m.group(2) ?? '';
    spans.add(TextSpan(
        text: content, style: base.copyWith(fontWeight: FontWeight.w700)));
    idx = m.end;
  }
  if (idx < s.length) spans.addAll(_mdItalic(s.substring(idx), base));
  return spans;
}
List<InlineSpan> _mdItalic(String s, TextStyle base) {
  final spans = <InlineSpan>[];
  final it = RegExp(r'(?<!\*)\*([^*\n]+?)\*(?!\*)|(?<!_)_([^_\n]+?)_(?!_)');
  int idx = 0;
  for (final m in it.allMatches(s)) {
    if (m.start > idx) {
      spans.add(TextSpan(text: s.substring(idx, m.start), style: base));
    }
    final content = m.group(1) ?? m.group(2) ?? '';
    spans.add(TextSpan(
        text: content, style: base.copyWith(fontStyle: FontStyle.italic)));
    idx = m.end;
  }
  if (idx < s.length) spans.add(TextSpan(text: s.substring(idx), style: base));
  return spans;
}
void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
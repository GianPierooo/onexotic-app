import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// Texto numérico que anima de 0 → [value] al cargar (counter premium).
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 900),
    this.prefix,
    this.suffix,
    this.style,
    this.fractionDigits = 0,
  });

  final num value;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final formatted = fractionDigits == 0
            ? v.round().toString()
            : v.toStringAsFixed(fractionDigits);
        return Text(
          '${prefix ?? ''}$formatted${suffix ?? ''}',
          style: style ?? AppTypography.metricLarge(),
        );
      },
    );
  }
}

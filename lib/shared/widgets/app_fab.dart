import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// FAB premium OnExotic — circular con glow accent naranja.
///
/// Usa DecoratedBox para el glow sin elevar el widget:
/// el FloatingActionButton hereda shape: CircleBorder del tema.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGlow,
            blurRadius: 22,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        tooltip: tooltip,
        child: Icon(icon, size: 24),
      ),
    );
  }
}

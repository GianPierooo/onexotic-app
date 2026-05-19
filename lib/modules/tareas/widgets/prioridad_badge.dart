import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class PrioridadBadge extends StatelessWidget {
  final String prioridad;

  const PrioridadBadge({super.key, required this.prioridad});

  static Color colorForPrioridad(String p) => switch (p) {
        'alta' => AppColors.error,
        'media' => AppColors.warning,
        'baja' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  static String labelForPrioridad(String p) => switch (p) {
        'alta' => 'Alta',
        'media' => 'Media',
        'baja' => 'Baja',
        _ => p,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorForPrioridad(prioridad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelForPrioridad(prioridad),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

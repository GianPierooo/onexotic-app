import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AsistenciaBar extends StatelessWidget {
  final double porcentaje; // 0.0 – 100.0
  final String mes;

  const AsistenciaBar({
    super.key,
    required this.porcentaje,
    required this.mes,
  });

  Color get _color {
    if (porcentaje >= 90) return AppColors.success;
    if (porcentaje >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final pct = porcentaje.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ASISTENCIA · $mes',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              porcentaje == 0 ? 'Sin datos' : '${pct.round()}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: porcentaje == 0 ? AppColors.textTertiary : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 4,
            backgroundColor: AppColors.surface3,
            valueColor: AlwaysStoppedAnimation<Color>(
              porcentaje == 0 ? AppColors.surface3 : color,
            ),
          ),
        ),
      ],
    );
  }
}

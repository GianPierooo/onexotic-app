import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class AreaBadge extends StatelessWidget {
  final String area;

  const AreaBadge({super.key, required this.area});

  static Color colorForArea(String a) => switch (a) {
        'tech' => AppColors.areaTech,
        'disenio' => AppColors.areaDisenio,
        'marketing' => AppColors.areaMarketing,
        'produccion' => AppColors.areaProduccion,
        'rrhh' => AppColors.areaRRHH,
        'legal' => AppColors.areaLegal,
        _ => AppColors.textSecondary,
      };

  static String labelForArea(String a) => switch (a) {
        'tech' => 'Tech',
        'disenio' => 'Diseño',
        'marketing' => 'Marketing',
        'produccion' => 'Producción',
        'rrhh' => 'RRHH',
        'legal' => 'Legal',
        _ => a,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorForArea(area);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            labelForArea(area),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

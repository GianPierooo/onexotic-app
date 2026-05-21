import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/analiticas_provider.dart';

class TareasPorAreaChart extends StatelessWidget {
  final Map<String, TareasArea> areas;
  const TareasPorAreaChart({super.key, required this.areas});

  static const _labels = <String, String>{
    'tech': 'Tech',
    'disenio': 'Diseño',
    'marketing': 'Marketing',
    'produccion': 'Producción',
    'rrhh': 'RRHH',
    'legal': 'Legal',
  };

  static const _colors = <String, Color>{
    'tech': AppColors.areaTech,
    'disenio': AppColors.areaDisenio,
    'marketing': AppColors.areaMarketing,
    'produccion': AppColors.areaProduccion,
    'rrhh': AppColors.areaRRHH,
    'legal': AppColors.areaLegal,
  };

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Sin tareas registradas',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final entries = areas.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return Column(
      children: entries.map((e) {
        final color = _colors[e.key] ?? AppColors.textSecondary;
        final label = _labels[e.key] ?? e.key;
        final total = e.value.total;
        final pct = e.value.porcentajeCompletadas;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value.completadas}/$total',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${pct.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: AppColors.surface2,
                    ),
                    LayoutBuilder(builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * (pct / 100),
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

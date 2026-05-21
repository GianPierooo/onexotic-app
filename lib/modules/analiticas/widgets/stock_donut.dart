import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class StockDonut extends StatelessWidget {
  final int sanos;
  final int criticos;
  final int agotados;

  const StockDonut({
    super.key,
    required this.sanos,
    required this.criticos,
    required this.agotados,
  });

  @override
  Widget build(BuildContext context) {
    final total = sanos + criticos + agotados;
    if (total == 0) {
      return _EmptyDonut();
    }
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                startDegreeOffset: -90,
                sections: [
                  _slice(sanos, AppColors.success),
                  _slice(criticos, AppColors.warning),
                  _slice(agotados, AppColors.error),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(
                    color: AppColors.success,
                    label: 'En stock',
                    value: sanos.toString()),
                const SizedBox(height: 10),
                _Legend(
                    color: AppColors.warning,
                    label: 'Críticos',
                    value: criticos.toString()),
                const SizedBox(height: 10),
                _Legend(
                    color: AppColors.error,
                    label: 'Agotados',
                    value: agotados.toString()),
                const SizedBox(height: 14),
                Text(
                  'Total: $total SKUs',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _slice(int value, Color color) {
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 28,
      showTitle: false,
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyDonut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          'Sin productos en inventario',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

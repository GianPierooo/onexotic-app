import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/analiticas_provider.dart';

class DropsBarChart extends StatelessWidget {
  final List<DropAnalitica> drops;
  const DropsBarChart({super.key, required this.drops});

  @override
  Widget build(BuildContext context) {
    if (drops.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Sin drops con productos',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final maxValor = drops.fold<double>(
            0, (max, d) => d.valorInventario > max ? d.valorInventario : max) *
        1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValor == 0 ? 100 : maxValor,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface3,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, _, rod, __) {
                final drop = drops[group.x];
                return BarTooltipItem(
                  '${drop.nombre}\nS/ ${_money(drop.valorInventario)}\n${drop.productos} SKUs',
                  GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValor / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border.withValues(alpha: 0.4),
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxValor / 4,
                getTitlesWidget: (value, _) => Text(
                  _moneyShort(value),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= drops.length) {
                    return const SizedBox.shrink();
                  }
                  final nombre = drops[idx].nombre;
                  final corto = nombre.length > 8
                      ? '${nombre.substring(0, 7)}…'
                      : nombre;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      corto,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < drops.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: drops[i].valorInventario,
                    color: AppColors.accent,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _money(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  static String _moneyShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/analiticas_provider.dart';
import '../widgets/asistencia_line_chart.dart';
import '../widgets/chart_card.dart';
import '../widgets/drops_bar_chart.dart';
import '../widgets/stock_donut.dart';
import '../widgets/tareas_por_area_chart.dart';

class AnaliticasScreen extends ConsumerWidget {
  const AnaliticasScreen({super.key});

  static String _money(double v) {
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analiticasAsync = ref.watch(analiticasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Analíticas',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Dashboard ejecutivo · solo CEO',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => ref.invalidate(analiticasProvider),
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: analiticasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
        error: (e, _) => _ErrorView(
          mensaje: e.toString(),
          onReintentar: () => ref.invalidate(analiticasProvider),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
          onRefresh: () async {
            ref.invalidate(analiticasProvider);
            await ref.read(analiticasProvider.future).catchError(
                  (_) => throw Exception('reload'),
                );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _buildKpiGrid(data),
              const SizedBox(height: 16),
              ChartCard(
                titulo: 'Estado del stock',
                subtitulo: 'Distribución de SKUs activos',
                child: StockDonut(
                  sanos: data.productosSanos,
                  criticos: data.productosCriticos,
                  agotados: data.productosAgotados,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: 16),
              ChartCard(
                titulo: 'Valor por drop',
                subtitulo: 'Inventario a precio de venta',
                child: DropsBarChart(drops: data.ventasPorDrop),
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
              const SizedBox(height: 16),
              ChartCard(
                titulo: 'Asistencia · últimos 7 días',
                subtitulo:
                    '${data.porcentajeAsistenciaSemanal.toStringAsFixed(0)}% promedio del equipo',
                child:
                    AsistenciaLineChart(dias: data.asistenciaSemanal),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              const SizedBox(height: 16),
              ChartCard(
                titulo: 'Tareas por área',
                subtitulo:
                    '${data.totalTareasCompletadas} completadas · ${data.totalTareasPendientes} pendientes',
                child: TareasPorAreaChart(areas: data.tareasPorArea),
              ).animate().fadeIn(duration: 300.ms, delay: 250.ms),
              const SizedBox(height: 16),
              ChartCard(
                titulo: 'Diseños por estado',
                subtitulo:
                    '${data.disenosAprobadosMes} aprobados este mes',
                child: _DisenosBreakdown(estados: data.disenosPorEstado),
              ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
              const SizedBox(height: 20),
              _ProductosPorTipo(porTipo: data.productosPorTipo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(AnaliticasData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnaliticaKpiTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Valor inventario',
                value: 'S/ ${_money(data.valorTotalInventario)}',
                color: AppColors.accent,
                helper: 'TOTAL',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnaliticaKpiTile(
                icon: Icons.trending_up_rounded,
                label: 'Margen potencial',
                value: 'S/ ${_money(data.margenPotencialTotal)}',
                color: AppColors.success,
                helper: 'BRUTO',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnaliticaKpiTile(
                icon: Icons.warning_amber_rounded,
                label: 'Stock crítico',
                value: '${data.productosCriticos}',
                color: AppColors.warning,
                helper: 'SKUs',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnaliticaKpiTile(
                icon: Icons.checklist_rtl_rounded,
                label: 'Tareas activas',
                value: '${data.totalTareasPendientes}',
                color: AppColors.info,
                helper: 'PENDIENTES',
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ─── Diseños breakdown ────────────────────────────────────────────────────────

class _DisenosBreakdown extends StatelessWidget {
  final Map<String, int> estados;
  const _DisenosBreakdown({required this.estados});

  static const _labels = <String, (String, Color)>{
    'brief': ('Briefs', AppColors.info),
    'proceso': ('En proceso', AppColors.warning),
    'avance': ('Avance', Color(0xFFF97316)),
    'revision': ('Revisión', AppColors.accent),
    'aprobado': ('Aprobado', AppColors.success),
    'rechazado': ('Rechazado', AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    if (estados.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Sin diseños registrados',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final total = estados.values.fold<int>(0, (a, b) => a + b);
    final entries = _labels.entries
        .where((e) => (estados[e.key] ?? 0) > 0)
        .toList();

    return Column(
      children: entries.map((entry) {
        final (label, color) = entry.value;
        final count = estados[entry.key] ?? 0;
        final pct = total == 0 ? 0.0 : (count / total) * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
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
        );
      }).toList(),
    );
  }
}

// ─── Productos por tipo ──────────────────────────────────────────────────────

class _ProductosPorTipo extends StatelessWidget {
  final Map<String, int> porTipo;
  const _ProductosPorTipo({required this.porTipo});

  static const _labels = <String, String>{
    'polo': 'Polos',
    'short': 'Shorts',
    'pantalon': 'Pantalones',
    'polera': 'Poleras',
    'accesorio': 'Accesorios',
  };

  @override
  Widget build(BuildContext context) {
    if (porTipo.isEmpty) return const SizedBox.shrink();

    return ChartCard(
      titulo: 'Productos por tipo',
      subtitulo: 'Distribución del catálogo activo',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: porTipo.entries.map((e) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _labels[e.key] ?? e.key,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.value}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 350.ms);
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar las métricas',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Reintentar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

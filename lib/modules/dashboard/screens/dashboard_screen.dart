import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../../shared/widgets/avatar.dart';
import '../../notificaciones/providers/notificaciones_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/acceso_rapido_ia.dart';
import '../widgets/actividad_reciente_list.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatFecha(DateTime d) {
    const dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  }

  String _formatDropBadge(DateTime d) {
    const m = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(notificacionesRecientesProvider);
    ref.invalidate(currentUserProvider);
    await ref.read(dashboardDataProvider.future).catchError(
          (_) => const DashboardData(
            stockCritico: 0,
            tareasPendientes: 0,
            presentesHoy: 0,
            totalEquipo: 0,
            diasProximoDrop: 0,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final dataAsync = ref.watch(dashboardDataProvider);
    final notifCount = ref.watch(notifSinLeerProvider);

    // Nombre: espera datos reales, no usa fallback hasta que el provider resuelve
    final nombre = userAsync.when(
      data: (u) => u?['nombre'] as String? ?? 'CEO',
      loading: () => '...',
      error: (e, _) => 'CEO',
    );
    final avatarUrl = userAsync.maybeWhen(
      data: (u) => u?['avatar_url'] as String?,
      orElse: () => null,
    );
    final rol = userAsync.valueOrNull?['rol'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'dashboard',
            slides: GuiasContent.dashboard,
          ),
          SafeArea(
            child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildHeader(context, nombre, avatarUrl, notifCount),
                ),
              ),

              // ── Contenido ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _SectionLabel('RESUMEN'),
                    const SizedBox(height: 14),
                    dataAsync.when(
                      loading: () => const _MetricasLoading(),
                      error: (e, _) => _ErrorBanner('$e'),
                      data: (data) => _buildMetricasGrid(context, data, rol: rol),
                    ),
                    const SizedBox(height: 28),
                    const ActividadRecienteList(),
                    const SizedBox(height: 28),
                    const _SectionLabel('ACCESO RAPIDO'),
                    const SizedBox(height: 14),
                    const AccesoRapidoIA(),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    String nombre,
    String? avatarUrl,
    int notifCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Avatar(nombre: nombre == '...' ? 'A' : nombre, imageUrl: avatarUrl, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_saludo, $nombre',
                style: AppTypography.sectionTitle(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatFecha(DateTime.now()),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const GuiaHelpButton(slides: GuiasContent.dashboard),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push('/notificaciones'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
              if (notifCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        notifCount > 9 ? '9+' : '$notifCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Grid 2×2 de métricas ─────────────────────────────────────────────────

  Widget _buildMetricasGrid(BuildContext context, DashboardData data,
      {String rol = ''}) {
    final dropBadge = data.fechaProximoDrop != null
        ? _formatDropBadge(data.fechaProximoDrop!)
        : 'Sin fecha definida';
    final dropValor = data.nombreProximoDrop == null
        ? 'Sin drops'
        : data.fechaProximoDrop != null
            ? data.diasProximoDrop <= 0
                ? '¡Hoy!'
                : '${data.diasProximoDrop}d'
            : data.nombreProximoDrop!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.inventory_2_outlined,
                value: '${data.stockCritico}',
                label: 'Stock crítico',
                badge: 'SKUs',
                valueColor: AppColors.error,
                // Diseñadora no puede acceder a inventario.
                onTap: rol == 'disenadora'
                    ? null
                    : () => context.go('/inventario'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.checklist_rounded,
                value: '${data.tareasPendientes}',
                label: 'Tareas pendientes',
                badge: 'hoy',
                valueColor: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.group_outlined,
                value: '${data.presentesHoy}/${data.totalEquipo}',
                label: 'Asistencia hoy',
                badge: 'equipo',
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.rocket_launch_outlined,
                value: dropValor,
                label: data.nombreProximoDrop ?? 'Próximo drop',
                badge: dropBadge,
                valueColor: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms);
  }
}

// ─── Widgets de soporte ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label(color: AppColors.textTertiary),
    );
  }
}

class _MetricasLoading extends StatelessWidget {
  const _MetricasLoading();

  Widget _card() => Expanded(
        child: Container(
          height: 116,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_card(), const SizedBox(width: 12), _card()]),
        const SizedBox(height: 12),
        Row(children: [_card(), const SizedBox(width: 12), _card()]),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

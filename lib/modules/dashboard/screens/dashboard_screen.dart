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
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
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
    ref.invalidate(dashboardDisenoraProvider);
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
                  delegate: SliverChildListDelegate(
                    rol == 'disenadora'
                        ? [
                            const _DisenoraContent(),
                            const SizedBox(height: 28),
                            const SectionLabel('ACCESO RAPIDO'),
                            const SizedBox(height: 14),
                            const AccesoRapidoIA(),
                            const SizedBox(height: 8),
                          ]
                        : [
                            const SectionLabel('RESUMEN'),
                            const SizedBox(height: 14),
                            dataAsync.when(
                              loading: () => const ShimmerMetricGrid(),
                              error: (e, _) => _ErrorBanner('$e'),
                              data: (data) =>
                                  _buildMetricasGrid(context, data, rol: rol),
                            ),
                            const SizedBox(height: 28),
                            const ActividadRecienteList(),
                            const SizedBox(height: 28),
                            const SectionLabel('ACCESO RAPIDO'),
                            const SizedBox(height: 14),
                            const AccesoRapidoIA(),
                            const SizedBox(height: 8),
                          ],
                  ),
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

// ─── Vista exclusiva para diseñadora ─────────────────────────────────────────

class _DisenoraContent extends ConsumerWidget {
  const _DisenoraContent();

  static Color _colorEstado(String e) => switch (e) {
        'brief'    => AppColors.info,
        'proceso'  => AppColors.warning,
        'avance'   => const Color(0xFFF97316),
        'revision' => AppColors.accent,
        _          => AppColors.textSecondary,
      };

  static String _labelEstado(String e) => switch (e) {
        'brief'    => 'Brief',
        'proceso'  => 'En proceso',
        'avance'   => 'Avance',
        'revision' => 'Revisión',
        _          => e,
      };

  static String _formatFechaCorta(DateTime d) {
    const meses = [
      'ene','feb','mar','abr','may','jun',
      'jul','ago','sep','oct','nov','dic'
    ];
    return '${d.day} ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardDisenoraProvider);

    return dataAsync.when(
      loading: () => const ShimmerMetricGrid(),
      error: (e, _) => _ErrorBanner('$e'),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row ──────────────────────────────────────────────────
          const SectionLabel('RESUMEN'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.brush_outlined,
                  value: '${data.disenosCount}',
                  label: 'En proceso',
                  badge: 'diseños',
                  valueColor: AppColors.accent,
                  onTap: () => context.go('/disenios'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  icon: Icons.assignment_outlined,
                  value: '${data.briefsCount}',
                  label: 'Briefs nuevos',
                  badge: 'pendiente',
                  valueColor: AppColors.info,
                  onTap: data.briefsCount > 0 ? () => context.go('/disenios') : null,
                ),
              ),
            ],
          ),

          // ── Próxima entrega ────────────────────────────────────────────
          if (data.proximaEntrega != null) ...[
            const SizedBox(height: 28),
            const SectionLabel('PRÓXIMA ENTREGA'),
            const SizedBox(height: 14),
            _ProximaEntregaCard(disenio: data.proximaEntrega!),
          ],

          // ── Diseños activos ────────────────────────────────────────────
          if (data.disenosActivos.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionLabel(
              'MIS DISEÑOS ACTIVOS',
              trailing: GestureDetector(
                onTap: () => context.go('/disenios'),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...data.disenosActivos.take(3).map(
              (d) => _DisenioMiniCard(
                titulo: d['titulo'] as String? ?? '',
                dropNombre: (d['drops'] as Map?)?['nombre'] as String?,
                estado: d['estado'] as String? ?? 'proceso',
                fechaLimite: d['fecha_limite'] != null
                    ? DateTime.tryParse(d['fecha_limite'] as String)
                    : null,
                version: d['version'] as int? ?? 1,
                colorEstado: _colorEstado(d['estado'] as String? ?? 'proceso'),
                labelEstado: _labelEstado(d['estado'] as String? ?? 'proceso'),
                formatFecha: _formatFechaCorta,
              ),
            ),
          ],

          // ── Briefs pendientes ──────────────────────────────────────────
          if (data.briefsPendientes.isNotEmpty) ...[
            const SizedBox(height: 28),
            const SectionLabel('BRIEFS PENDIENTES'),
            const SizedBox(height: 14),
            ...data.briefsPendientes.take(3).map(
              (d) => _DisenioMiniCard(
                titulo: d['titulo'] as String? ?? '',
                dropNombre: (d['drops'] as Map?)?['nombre'] as String?,
                estado: 'brief',
                fechaLimite: d['fecha_limite'] != null
                    ? DateTime.tryParse(d['fecha_limite'] as String)
                    : null,
                version: d['version'] as int? ?? 1,
                colorEstado: _colorEstado('brief'),
                labelEstado: _labelEstado('brief'),
                formatFecha: _formatFechaCorta,
              ),
            ),
          ],

          // ── Último feedback CEO ────────────────────────────────────────
          if (data.ultimoFeedback != null) ...[
            const SizedBox(height: 28),
            const SectionLabel('ÚLTIMO FEEDBACK'),
            const SizedBox(height: 14),
            _FeedbackCard(
              titulo: data.ultimoFeedbackTitulo ?? 'Diseño',
              feedback: data.ultimoFeedback!,
            ),
          ],

          // ── Empty state ────────────────────────────────────────────────
          if (data.disenosCount == 0 && data.briefsCount == 0)
            _DisenadoraEmptyState(),
        ],
      ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
    );
  }
}

class _ProximaEntregaCard extends StatelessWidget {
  final Map<String, dynamic> disenio;
  const _ProximaEntregaCard({required this.disenio});

  @override
  Widget build(BuildContext context) {
    final titulo = disenio['titulo'] as String? ?? '';
    final estado = disenio['estado'] as String? ?? 'proceso';
    final fechaStr = disenio['fecha_limite'] as String?;
    final fecha = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    final hoy = DateTime.now();
    int? diasRestantes;
    if (fecha != null) {
      diasRestantes = DateTime(fecha.year, fecha.month, fecha.day)
          .difference(DateTime(hoy.year, hoy.month, hoy.day))
          .inDays;
    }
    final urgente = diasRestantes != null && diasRestantes <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgente
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgente
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
          width: urgente ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (urgente ? AppColors.error : AppColors.accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: urgente ? AppColors.error : AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _labelEstado(estado),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                diasRestantes == null
                    ? 'Sin fecha'
                    : diasRestantes <= 0
                        ? '¡Hoy!'
                        : '${diasRestantes}d',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: urgente ? AppColors.error : AppColors.textPrimary,
                  height: 1,
                ),
              ),
              if (fecha != null)
                Text(
                  '${fecha.day}/${fecha.month}/${fecha.year}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _labelEstado(String e) => switch (e) {
        'brief'    => 'Sin comenzar',
        'proceso'  => 'En proceso',
        'avance'   => 'Avance subido',
        'revision' => 'En revisión',
        _          => e,
      };
}

class _DisenioMiniCard extends StatelessWidget {
  final String titulo;
  final String? dropNombre;
  final String estado;
  final DateTime? fechaLimite;
  final int version;
  final Color colorEstado;
  final String labelEstado;
  final String Function(DateTime) formatFecha;

  const _DisenioMiniCard({
    required this.titulo,
    this.dropNombre,
    required this.estado,
    this.fechaLimite,
    required this.version,
    required this.colorEstado,
    required this.labelEstado,
    required this.formatFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colorEstado,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  dropNombre != null
                      ? 'Drop $dropNombre · v$version'
                      : 'v$version',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labelEstado,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorEstado,
                  ),
                ),
              ),
              if (fechaLimite != null) ...[
                const SizedBox(height: 4),
                Text(
                  formatFecha(fechaLimite!),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String titulo;
  final String feedback;
  const _FeedbackCard({required this.titulo, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.feedback_outlined,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisenadoraEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.brush_outlined,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Todo al día · Sin diseños activos',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando tengas briefs o diseños en\nproceso aparecerán aquí',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

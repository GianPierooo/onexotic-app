import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../equipo/widgets/rol_badge.dart';
import '../providers/perfil_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(perfilStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.inter(color: AppColors.error)),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Perfil no disponible',
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Contacta a un CEO para configurar tu perfil',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              );
            }
            final nombre = user['nombre'] as String? ?? '';
            final email = user['email'] as String? ?? '';
            final rol = user['rol'] as String? ?? 'ceo';
            final horario = user['horario'] as String?;
            final tema = user['tema'] as String? ?? 'dark';
            final isLight = tema == 'light';

            final parts = nombre.trim().split(' ');
            final initials = parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : nombre.isNotEmpty
                    ? nombre[0].toUpperCase()
                    : 'GP';

            final avatarColor = switch (rol) {
              'ceo'        => AppColors.accent,
              'manager'    => AppColors.info,
              'disenadora' => const Color(0xFF8B5CF6),
              'rrhh'       => AppColors.warning,
              'produccion' => AppColors.success,
              _            => AppColors.accent,
            };

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Avatar + info ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anillo decorativo sutil
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: avatarColor
                                      .withValues(alpha: 0.18),
                                  width: 1,
                                ),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: avatarColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: avatarColor
                                        .withValues(alpha: 0.32),
                                    blurRadius: 24,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          nombre,
                          style: AppTypography.screenTitle(
                            color: AppColors.textPrimary,
                          ).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (horario != null && horario.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Turno: $horario',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        RolBadge(rol: rol),
                      ],
                    ).animate().fadeIn(duration: 350.ms),
                  ),

                  const SizedBox(height: 32),

                  // ── Grid de métricas 2×2 ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: statsAsync.when(
                      loading: () => const _StatsLoading(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.access_time_rounded,
                                  valor: '${stats.asistenciaPct.round()}%',
                                  label: 'Asistencia',
                                  sublabel: 'este mes',
                                  color: stats.asistenciaPct >= 90
                                      ? AppColors.success
                                      : stats.asistenciaPct >= 70
                                          ? AppColors.warning
                                          : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.checklist_rounded,
                                  valor: '${stats.tareasCompletadas}',
                                  label: 'Tareas',
                                  sublabel: 'completadas',
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.brush_rounded,
                                  valor: '${stats.disenosAprobados}',
                                  label: 'Diseños',
                                  sublabel: 'aprobados',
                                  color: const Color(0xFFA78BFA),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.local_fire_department_rounded,
                                  valor: '${stats.rachaActual}d',
                                  label: 'Racha',
                                  sublabel: 'días seguidos',
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 100.ms),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Ajustes ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AJUSTES',
                          style: AppTypography.label(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              _SettingRow(
                                icon: isLight
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                iconColor: AppColors.warning,
                                label: 'Tema',
                                sublabel: isLight ? 'Claro' : 'Oscuro',
                                trailing: Switch.adaptive(
                                  value: isLight,
                                  onChanged: (val) {
                                    final nuevoTema =
                                        val ? 'light' : 'dark';
                                    ref
                                        .read(actualizarTemaProvider.notifier)
                                        .cambiar(nuevoTema);
                                  },
                                  activeThumbColor: AppColors.accent,
                                  inactiveThumbColor:
                                      AppColors.textTertiary,
                                  inactiveTrackColor: AppColors.surface3,
                                ),
                              ),
                              Container(
                                height: 0.5,
                                color: AppColors.border,
                                margin: const EdgeInsets.only(left: 56),
                              ),
                              _SettingRow(
                                icon: Icons.notifications_outlined,
                                iconColor: AppColors.info,
                                label: 'Notificaciones',
                                sublabel: 'Gestionar alertas',
                                trailing: _Chevron(
                                  onTap: () =>
                                      context.push('/notificaciones'),
                                ),
                              ),
                              Container(
                                height: 0.5,
                                color: AppColors.border,
                                margin: const EdgeInsets.only(left: 56),
                              ),
                              _SettingRow(
                                icon: Icons.info_outline_rounded,
                                iconColor: AppColors.textSecondary,
                                label: 'Versión',
                                sublabel: '1.0.0',
                                trailing: SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Cerrar sesión ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: AppColors.border),
                              ),
                              title: Text(
                                'Cerrar sesión',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                '¿Estás seguro que quieres cerrar sesión?',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text(
                                    'Cerrar sesión',
                                    style: GoogleFonts.inter(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await cerrarSesion(ref);
                            if (context.mounted) context.go('/login');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color:
                                AppColors.error.withValues(alpha: 0.45),
                          ),
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.06),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          'Cerrar sesión',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String label;
  final String sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.valor,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Chevron extends StatefulWidget {
  final VoidCallback onTap;
  const _Chevron({required this.onTap});

  @override
  State<_Chevron> createState() => _ChevronState();
}

class _ChevronState extends State<_Chevron> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          offset: _hovered ? const Offset(0.2, 0) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

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

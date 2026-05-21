import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_fab.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/calendario_provider.dart';
import '../widgets/leyenda_colores.dart';
import '../widgets/mes_grid.dart';
import 'nuevo_evento_sheet.dart';

class CalendarioScreen extends ConsumerWidget {
  const CalendarioScreen({super.key});

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  void _abrirNuevoEvento(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const NuevoEventoSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSeleccionadoProvider);
    final vista = ref.watch(vistaCalendarioProvider);
    final semana = ref.watch(semanaSeleccionadaProvider);
    final eventosAsync = ref.watch(calendarioEventosProvider);

    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
        data: (u) => u?['rol'] as String? ?? '', orElse: () => '');
    final isCeo = rol == 'ceo' || rol == 'manager';

    final hoy = DateTime.now();
    final esHoy = mes.year == hoy.year && mes.month == hoy.month;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isCeo
          ? AppFab(onPressed: () => _abrirNuevoEvento(context))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Mes anterior
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => ref
                        .read(mesSeleccionadoProvider.notifier)
                        .state = DateTime(mes.year, mes.month - 1),
                  ),

                  // Botón "Hoy" centrado
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: esHoy
                        ? null
                        : () {
                            final h = DateTime.now();
                            ref.read(mesSeleccionadoProvider.notifier).state =
                                DateTime(h.year, h.month);
                            ref
                                .read(semanaSeleccionadaProvider.notifier)
                                .state = h.subtract(
                                    Duration(days: h.weekday - 1));
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            esHoy ? AppColors.surface3 : AppColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: esHoy
                                ? AppColors.border
                                : AppColors.borderHover),
                      ),
                      child: Text(
                        'Hoy',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: esHoy
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mes y año
                  Expanded(
                    child: Text(
                      '${_meses[mes.month - 1]} ${mes.year}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Mes siguiente
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => ref
                        .read(mesSeleccionadoProvider.notifier)
                        .state = DateTime(mes.year, mes.month + 1),
                  ),
                  const SizedBox(width: 8),

                  // Toggle Mes / Semana
                  _ToggleVista(),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 12),

            // ── Loading ───────────────────────────────────────────────────
            if (eventosAsync.isLoading)
              const LinearProgressIndicator(
                color: AppColors.accent,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),

            // ── Contenido ─────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: vista == 'mes'
                    ? SingleChildScrollView(
                        key: ValueKey('mes_${mes.year}_${mes.month}'),
                        child: const Column(
                          children: [MesGrid(), SizedBox(height: 8)],
                        ),
                      )
                    : _VistaSemana(
                        key: ValueKey(
                            'semana_${semana.year}_${semana.month}_${semana.day}')),
              ),
            ),

            // ── Leyenda siempre visible ───────────────────────────────────
            const LeyendaColores(),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de navegación ──────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}

// ─── Toggle Mes / Semana ──────────────────────────────────────────────────────

class _ToggleVista extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaCalendarioProvider);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: 'Mes',
            activo: vista == 'mes',
            onTap: () =>
                ref.read(vistaCalendarioProvider.notifier).state = 'mes',
          ),
          _Tab(
            label: 'Semana',
            activo: vista == 'semana',
            onTap: () =>
                ref.read(vistaCalendarioProvider.notifier).state = 'semana',
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: activo ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: activo ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Vista semanal con swipe ──────────────────────────────────────────────────

class _VistaSemana extends ConsumerStatefulWidget {
  const _VistaSemana({super.key});

  @override
  ConsumerState<_VistaSemana> createState() => _VistaSemanaState();
}

class _VistaSemanaState extends ConsumerState<_VistaSemana> {
  static const _diasLabel = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _horas = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

  @override
  Widget build(BuildContext context) {
    final semana = ref.watch(semanaSeleccionadaProvider);
    final eventosAsync = ref.watch(calendarioEventosProvider);
    final eventos = eventosAsync.maybeWhen(
      data: (e) => e,
      orElse: () => <String, List<EventoCalendario>>{},
    );

    final hoy = DateTime.now();
    final diasSemana = List.generate(7, (i) => semana.add(Duration(days: i)));

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final vel = details.primaryVelocity ?? 0;
        if (vel < -300) {
          ref.read(semanaSeleccionadaProvider.notifier).state =
              semana.add(const Duration(days: 7));
          ref.read(mesSeleccionadoProvider.notifier).state = DateTime(
              semana.add(const Duration(days: 7)).year,
              semana.add(const Duration(days: 7)).month);
        } else if (vel > 300) {
          ref.read(semanaSeleccionadaProvider.notifier).state =
              semana.subtract(const Duration(days: 7));
          ref.read(mesSeleccionadoProvider.notifier).state = DateTime(
              semana.subtract(const Duration(days: 7)).year,
              semana.subtract(const Duration(days: 7)).month);
        }
      },
      child: Column(
        children: [
          // ── Cabecera L M M J V S D ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const SizedBox(width: 36),
                ...diasSemana.asMap().entries.map((entry) {
                  final d = entry.value;
                  final esHoy = d.year == hoy.year &&
                      d.month == hoy.month &&
                      d.day == hoy.day;
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          _diasLabel[entry.key],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: esHoy
                              ? const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Center(
                            child: Text(
                              '${d.day}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: esHoy
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: esHoy
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: AppColors.border, height: 1),

          // ── Grid de horas ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _horas.map((hora) {
                  return SizedBox(
                    height: 52,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 6, top: 4),
                            child: Text(
                              '${hora}h',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        ...diasSemana.map((d) {
                          final key = dateStr(DateTime(d.year, d.month, d.day));
                          final eventosDelDia = eventos[key] ?? [];
                          final enHora = eventosDelDia
                              .where((e) =>
                                  e.hora != null && e.hora!.hour == hora)
                              .toList();
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                      color: AppColors.border, width: 0.5),
                                  bottom: BorderSide(
                                      color: AppColors.border, width: 0.3),
                                ),
                              ),
                              child: enHora.isEmpty
                                  ? const SizedBox()
                                  : Container(
                                      margin: const EdgeInsets.all(2),
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: enHora.first.color
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                          color: enHora.first.color
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        enHora.first.titulo,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: enHora.first.color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

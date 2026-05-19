import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/calendario_provider.dart';
import 'eventos_sheet.dart';

class DiaCell extends ConsumerWidget {
  final DateTime fecha;
  final bool esDelMes;
  final List<EventoCalendario> eventos;

  const DiaCell({
    super.key,
    required this.fecha,
    required this.esDelMes,
    required this.eventos,
  });

  bool _esHoy() {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  void _abrirSheet(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EventosSheet(fecha: fecha, eventos: eventos),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaSeleccionado = ref.watch(diaSeleccionadoProvider);
    final esHoy = _esHoy();
    final esSelecc = diaSeleccionado != null &&
        diaSeleccionado.year == fecha.year &&
        diaSeleccionado.month == fecha.month &&
        diaSeleccionado.day == fecha.day &&
        !esHoy;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(diaSeleccionadoProvider.notifier).state = fecha;
        _abrirSheet(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: esSelecc ? AppColors.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: esSelecc
              ? Border.all(color: AppColors.border, width: 0.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: esHoy
                  ? BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : null,
              child: Center(
                child: Text(
                  '${fecha.day}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight:
                        esHoy ? FontWeight.w700 : FontWeight.w500,
                    color: esHoy
                        ? Colors.white
                        : esDelMes
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _PuntosEventos(eventos: eventos),
          ],
        ),
      ),
    );
  }
}

class _PuntosEventos extends StatelessWidget {
  final List<EventoCalendario> eventos;

  const _PuntosEventos({required this.eventos});

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) return const SizedBox(height: 6);

    final tiposUnicos = eventos.map((e) => e.tipo).toSet().toList();
    final mostrar = tiposUnicos.take(3).toList();
    final hayMas = tiposUnicos.length > 3;

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...mostrar.map((tipo) {
            final c = EventoCalendario.colorForTipo(tipo);
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.45),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
          if (hayMas)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

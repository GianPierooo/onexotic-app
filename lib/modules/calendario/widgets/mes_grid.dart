import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/calendario_provider.dart';
import 'dia_cell.dart';

class MesGrid extends ConsumerWidget {
  const MesGrid({super.key});

  static const _cabeceras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSeleccionadoProvider);
    final eventosAsync = ref.watch(calendarioEventosProvider);

    final eventos = eventosAsync.maybeWhen(
      data: (e) => e,
      orElse: () => <String, List<EventoCalendario>>{},
    );

    // Primer día del mes y offset (semana empieza el lunes)
    final primerDia = DateTime(mes.year, mes.month, 1);
    final offsetInicio = (primerDia.weekday - 1) % 7; // L=0, D=6

    // Último día del mes
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;

    // Días del mes anterior para rellenar el inicio
    final ultimoDiaPrevio = DateTime(mes.year, mes.month, 0).day;
    final mesPrevio = DateTime(mes.year, mes.month - 1);

    // Construir la lista de fechas del grid
    final cells = <DateTime>[];

    // Leading: días del mes anterior
    for (int i = 0; i < offsetInicio; i++) {
      cells.add(DateTime(
        mesPrevio.year,
        mesPrevio.month,
        ultimoDiaPrevio - offsetInicio + 1 + i,
      ));
    }

    // Días del mes actual
    for (int d = 1; d <= ultimoDia; d++) {
      cells.add(DateTime(mes.year, mes.month, d));
    }

    // Trailing: días del mes siguiente para completar la última semana
    final mesProximo = DateTime(mes.year, mes.month + 1);
    final trailing = (7 - cells.length % 7) % 7;
    for (int i = 1; i <= trailing; i++) {
      cells.add(DateTime(mesProximo.year, mesProximo.month, i));
    }

    return Column(
      children: [
        // ── Cabecera L M M J V S D ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _cabeceras
                .map((h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // ── Grid de días ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
            ),
            itemCount: cells.length,
            itemBuilder: (context, i) {
              final fecha = cells[i];
              final esDelMes = fecha.month == mes.month;
              final key = dateStr(DateTime(fecha.year, fecha.month, fecha.day));
              final eventosDelDia = eventos[key] ?? [];

              return DiaCell(
                key: ValueKey('$fecha'),
                fecha: fecha,
                esDelMes: esDelMes,
                eventos: eventosDelDia,
              );
            },
          ),
        ),
      ],
    );
  }
}

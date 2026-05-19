import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/asistencia_provider.dart';

class MiniCalendarioSemanal extends ConsumerWidget {
  const MiniCalendarioSemanal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semanaAsync = ref.watch(semanaAsistenciaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Esta semana',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {}, // historial_screen (próximamente)
              child: Text(
                'Ver mes →',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: semanaAsync.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox(height: 56),
            data: (dias) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dias.map((dia) => _DiaCell(dia: dia)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiaCell extends StatelessWidget {
  final DiaSemana dia;
  const _DiaCell({required this.dia});

  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool get _isToday {
    final now = DateTime.now();
    return dia.fecha.year == now.year &&
        dia.fecha.month == now.month &&
        dia.fecha.day == now.day;
  }

  Color? get _dotColor => switch (dia.estado) {
        EstadoSemana.todos     => AppColors.success,
        EstadoSemana.parcial   => AppColors.warning,
        EstadoSemana.ausencias => AppColors.error,
        null                   => null,
      };

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday;
    final dotColor = _dotColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre del día
        Text(
          _dayNames[dia.fecha.weekday - 1],
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),

        // Número del día con círculo si es hoy
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isToday ? AppColors.accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${dia.fecha.day}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isToday ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Punto de estado
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor ?? Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

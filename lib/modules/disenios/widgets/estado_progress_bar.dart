import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'estado_chip.dart';

class EstadoProgressBar extends StatelessWidget {
  final String estado;

  const EstadoProgressBar({super.key, required this.estado});

  static const _pasos = [
    'brief',
    'proceso',
    'avance',
    'revision',
    'aprobado',
  ];

  static const _labels = [
    'Brief',
    'Proceso',
    'Avance',
    'Revisión',
    'Aprobado',
  ];

  @override
  Widget build(BuildContext context) {
    final esRechazado = estado == 'rechazado';
    final esCancelado = estado == 'cancelado';
    final fueraFlujo = esRechazado || esCancelado;

    final indice = EstadoChip.indiceEstado(estado);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra visual
        Row(
          children: List.generate(_pasos.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Conector
              final pasoIdx = (i - 1) ~/ 2;
              final activo = !fueraFlujo && pasoIdx < indice - 1;
              final actual = !fueraFlujo && pasoIdx == indice - 1;
              return Expanded(
                child: Container(
                  height: 2,
                  color: (activo || actual)
                      ? AppColors.accent
                      : AppColors.border,
                ),
              );
            }
            // Nodo
            final pasoIdx = i ~/ 2;
            final esActual = !fueraFlujo && pasoIdx == indice;
            final completado = !fueraFlujo && pasoIdx < indice;

            return _Nodo(
              label: _labels[pasoIdx],
              esActual: esActual,
              completado: completado,
              fueraFlujo: fueraFlujo,
            );
          }),
        ),

        // Estado especial fuera del flujo
        if (fueraFlujo) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: EstadoChip.colorForEstado(estado).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: EstadoChip.colorForEstado(estado)
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esRechazado
                      ? Icons.cancel_outlined
                      : Icons.block_rounded,
                  size: 13,
                  color: EstadoChip.colorForEstado(estado),
                ),
                const SizedBox(width: 6),
                Text(
                  esRechazado
                      ? 'Rechazado · requiere correcciones'
                      : 'Cancelado',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: EstadoChip.colorForEstado(estado),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Nodo extends StatelessWidget {
  final String label;
  final bool esActual;
  final bool completado;
  final bool fueraFlujo;

  const _Nodo({
    required this.label,
    required this.esActual,
    required this.completado,
    required this.fueraFlujo,
  });

  @override
  Widget build(BuildContext context) {
    final color = (esActual || completado) && !fueraFlujo
        ? AppColors.accent
        : AppColors.borderHover;

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: completado && !fueraFlujo ? AppColors.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: esActual ? 2.5 : 1.5),
          ),
          child: completado && !fueraFlujo
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : esActual
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: esActual ? FontWeight.w700 : FontWeight.w400,
            color: esActual
                ? AppColors.accent
                : completado
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

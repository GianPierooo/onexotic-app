import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstadoChip extends StatelessWidget {
  final String estado;

  const EstadoChip({super.key, required this.estado});

  static Color colorForEstado(String e) => switch (e) {
        'brief'     => const Color(0xFF3B82F6),
        'proceso'   => const Color(0xFFF59E0B),
        'avance'    => const Color(0xFF8B5CF6),
        'revision'  => const Color(0xFFFF4500),
        'aprobado'  => const Color(0xFF22C55E),
        'rechazado' => const Color(0xFFEF4444),
        'cancelado' => const Color(0xFF555555),
        _           => const Color(0xFF888888),
      };

  static String labelForEstado(String e) => switch (e) {
        'brief'     => 'Brief',
        'proceso'   => 'En proceso',
        'avance'    => 'Avance',
        'revision'  => 'Revisión',
        'aprobado'  => 'Aprobado',
        'rechazado' => 'Rechazado',
        'cancelado' => 'Cancelado',
        _           => e,
      };

  // Índice en el flujo (para barra de progreso)
  static int indiceEstado(String e) => switch (e) {
        'brief'    => 0,
        'proceso'  => 1,
        'avance'   => 2,
        'revision' => 3,
        'aprobado' => 4,
        _          => -1, // rechazado, cancelado fuera del flujo lineal
      };

  @override
  Widget build(BuildContext context) {
    final color = colorForEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            labelForEstado(estado),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

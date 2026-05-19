import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/avatar.dart';
import '../providers/asistencia_provider.dart';

class MiembroAsistenciaItem extends StatelessWidget {
  final MiembroConEstado miembro;

  const MiembroAsistenciaItem({super.key, required this.miembro});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Avatar(
            nombre: miembro.nombre,
            size: 44,
            color: _colorForRol(miembro.rol),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  miembro.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _labelRol(miembro.rol),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          _EstadoBadge(estado: miembro.estado),
        ],
      ),
    );
  }

  Color _colorForRol(String rol) => switch (rol) {
        'ceo' => const Color(0xFFF59E0B),
        'manager' => const Color(0xFFF97316),
        'disenadora' => const Color(0xFFA78BFA),
        'rrhh' => const Color(0xFF3B82F6),
        'produccion' => const Color(0xFF22C55E),
        _ => AppColors.textSecondary,
      };

  String _labelRol(String rol) => switch (rol) {
        'ceo' => 'CEO',
        'manager' => 'Manager',
        'disenadora' => 'Diseñadora',
        'rrhh' => 'RRHH',
        'produccion' => 'Producción',
        _ => rol,
      };
}

class _EstadoBadge extends StatelessWidget {
  final EstadoAsistencia estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (estado) {
      EstadoAsistencia.presente => (
        'PRESENTE',
        AppColors.success,
        Icons.check_circle_rounded
      ),
      EstadoAsistencia.ausente => (
        'AUSENTE',
        AppColors.error,
        Icons.cancel_rounded
      ),
      EstadoAsistencia.pendiente => (
        'PENDIENTE',
        AppColors.warning,
        Icons.schedule_rounded
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

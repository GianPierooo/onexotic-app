import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';

class ActividadRecienteItem extends StatelessWidget {
  final Map<String, dynamic> notificacion;

  const ActividadRecienteItem({super.key, required this.notificacion});

  @override
  Widget build(BuildContext context) {
    final tipo = notificacion['tipo'] as String? ?? 'sistema';
    final titulo = notificacion['titulo'] as String? ?? '';
    final mensaje = notificacion['mensaje'] as String? ?? '';
    final leido = notificacion['leido'] as bool? ?? false;
    final rawDate = notificacion['created_at'] as String?;
    final createdAt =
        rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono circular por tipo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colorForTipo(tipo).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForTipo(tipo),
              size: 16,
              color: _colorForTipo(tipo),
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              leido ? FontWeight.w400 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(createdAt, locale: 'es'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (mensaje.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    mensaje,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Punto no leído
          if (!leido) ...[
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 3),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorForTipo(String tipo) => switch (tipo) {
        'asistencia' => AppColors.success,
        'disenio'    => AppColors.areaDisenio,
        'tarea'      => AppColors.accent,
        'inventario' => AppColors.error,
        'bono'       => AppColors.warning,
        _            => AppColors.info,
      };

  IconData _iconForTipo(String tipo) => switch (tipo) {
        'asistencia' => Icons.check_circle_outline_rounded,
        'disenio'    => Icons.palette_outlined,
        'tarea'      => Icons.task_alt_rounded,
        'inventario' => Icons.inventory_2_outlined,
        'bono'       => Icons.monetization_on_outlined,
        _            => Icons.notifications_outlined,
      };
}

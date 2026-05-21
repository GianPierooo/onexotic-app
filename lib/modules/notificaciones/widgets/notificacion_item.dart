import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../providers/notificaciones_provider.dart';

class NotificacionItem extends ConsumerWidget {
  final Notificacion notif;
  final int index;
  final VoidCallback? onTap;

  const NotificacionItem({
    super.key,
    required this.notif,
    this.index = 0,
    this.onTap,
  });

  IconData _iconForTipo(String tipo) => switch (tipo) {
        'asistencia' => Icons.access_time_rounded,
        'disenio' => Icons.brush_rounded,
        'tarea' => Icons.checklist_rounded,
        'inventario' => Icons.inventory_2_outlined,
        'bono' => Icons.monetization_on_outlined,
        'chat' => Icons.chat_bubble_outline_rounded,
        _ => Icons.notifications_outlined,
      };

  Color _colorForTipo(String tipo) => switch (tipo) {
        'asistencia' => AppColors.info,
        'disenio' => const Color(0xFFA78BFA),
        'tarea' => AppColors.accent,
        'inventario' => AppColors.error,
        'bono' => const Color(0xFFF59E0B),
        'chat' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  String _safeTimeago(DateTime dt) {
    try {
      return timeago.format(dt, locale: 'es');
    } catch (_) {
      try {
        return timeago.format(dt);
      } catch (_) {
        return '';
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForTipo(notif.tipo);
    final isNew = !notif.leido;
    final dismissKey = ValueKey(
      notif.id.isEmpty
          ? 'notif-${identityHashCode(notif)}'
          : 'notif-${notif.id}',
    );

    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: 20,
        ),
      ),
      confirmDismiss: (_) async {
        await ref.read(eliminarNotifProvider.notifier).eliminar(notif.id);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isNew ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNew
                ? AppColors.accent.withValues(alpha: 0.25)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          dense: true,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForTipo(notif.tipo), size: 17, color: color),
          ),
          title: Text(
            notif.titulo,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isNew ? FontWeight.w600 : FontWeight.w400,
              color: isNew ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: notif.mensaje != null && notif.mensaje!.isNotEmpty
              ? Text(
                  notif.mensaje!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Text(
            _safeTimeago(notif.createdAt),
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: isNew ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 260.ms,
            delay: (index * 35).ms,
            curve: Curves.easeOut,
          )
          .moveY(
            begin: 6,
            end: 0,
            duration: 280.ms,
            delay: (index * 35).ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}

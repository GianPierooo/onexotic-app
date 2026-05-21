import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../chat/providers/bandeja_provider.dart';
import '../../equipo/widgets/rol_badge.dart';

class BandejaMensajesBlock extends ConsumerWidget {
  const BandejaMensajesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversacionesConMensajesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          'MENSAJES',
          trailing: GestureDetector(
            onTap: () => context.push('/mensajes'),
            child: Text(
              'Ver todos',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        convsAsync.when(
          loading: () => const _SkeletonList(),
          error: (e, _) => _EmptyCard(
            onTap: () => context.push('/mensajes'),
            mensaje: 'No se pudo cargar la bandeja',
          ),
          data: (lista) {
            if (lista.isEmpty) {
              return _EmptyCard(
                onTap: () => context.push('/mensajes'),
                mensaje: 'Empieza una conversación con tu equipo',
              );
            }
            final top = lista.take(3).toList();
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map((e) => _MensajeMiniCard(
                        preview: e.value,
                        index: e.key,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MensajeMiniCard extends StatelessWidget {
  final ConversacionPreview preview;
  final int index;

  const _MensajeMiniCard({required this.preview, required this.index});

  String _hora(DateTime d) {
    final ahora = DateTime.now();
    final mismaFecha =
        ahora.year == d.year && ahora.month == d.month && ahora.day == d.day;
    if (mismaFecha) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final diff = DateTime(ahora.year, ahora.month, ahora.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 1) return 'ayer';
    if (diff < 7) {
      const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      return dias[d.weekday - 1];
    }
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final otro = preview.otro;
    final rolColor = RolBadge.colorForRol(otro.rol);
    final tieneSinLeer = preview.sinLeer > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tieneSinLeer ? AppColors.surface2 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tieneSinLeer
              ? AppColors.accent.withValues(alpha: 0.25)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/mensajes/chat', extra: otro),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rolColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rolColor.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _iniciales(otro.nombre),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rolColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otro.nombre,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: tieneSinLeer
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (preview.ultimaFecha != null)
                            Text(
                              _hora(preview.ultimaFecha!),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: tieneSinLeer
                                    ? AppColors.accent
                                    : AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (preview.ultimoFueMio)
                            Text(
                              'Tú: ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              preview.ultimoMensaje ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: tieneSinLeer
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: tieneSinLeer
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tieneSinLeer) ...[
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  preview.sinLeer > 9 ? '9+' : '${preview.sinLeer}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 260.ms,
          delay: (index * 50).ms,
          curve: Curves.easeOut,
        );
  }

  String _iniciales(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (nombre.isNotEmpty) return nombre[0].toUpperCase();
    return '?';
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onTap;
  final String mensaje;

  const _EmptyCard({required this.onTap, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
        ),
      ),
    );
  }
}

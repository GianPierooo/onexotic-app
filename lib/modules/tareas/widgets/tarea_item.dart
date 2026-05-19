import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/tarea.dart';
import '../providers/tareas_provider.dart';
import 'area_badge.dart';
import 'prioridad_badge.dart';

String _inicialesDeId(String? userId, List<UsuarioSimple> usuarios) {
  if (userId == null) return '';
  try {
    return usuarios.firstWhere((u) => u.id == userId).iniciales;
  } catch (_) {
    return '?';
  }
}

class TareaItem extends ConsumerStatefulWidget {
  final Tarea tarea;
  final VoidCallback? onTap;

  const TareaItem({super.key, required this.tarea, this.onTap});

  @override
  ConsumerState<TareaItem> createState() => _TareaItemState();
}

class _TareaItemState extends ConsumerState<TareaItem>
    with SingleTickerProviderStateMixin {
  bool _toggling = false;
  bool _pressed = false;
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    final wasCompleted = widget.tarea.completado;
    setState(() => _toggling = true);
    HapticFeedback.mediumImpact();
    if (!wasCompleted) {
      _bounce.forward(from: 0);
    }
    await ref.read(toggleTareaProvider.notifier).toggle(
          widget.tarea.id,
          completado: !wasCompleted,
        );
    if (mounted) setState(() => _toggling = false);
  }

  String? _formatFecha(DateTime? d) {
    if (d == null) return null;
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hoy = DateTime.now();
    final diff = d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff < 0) return 'Venció';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff <= 7) return 'en $diff días';
    return '${d.day} ${meses[d.month - 1]}';
  }

  Color _fechaColor(DateTime? d) {
    if (d == null) return AppColors.textTertiary;
    final hoy = DateTime.now();
    final diff = d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff <= 0) return AppColors.error;
    if (diff <= 2) return AppColors.warning;
    return AppColors.textTertiary;
  }

  IconData? _fechaIcon(DateTime? d) {
    if (d == null) return null;
    final hoy = DateTime.now();
    final diff = d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff < 0) return Icons.error_outline_rounded;
    if (diff <= 2) return Icons.schedule_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final completado = widget.tarea.completado;
    final fechaStr = _formatFecha(widget.tarea.fechaLimite);
    final fechaCol = _fechaColor(widget.tarea.fechaLimite);
    final fechaIc = _fechaIcon(widget.tarea.fechaLimite);
    final usuarios = ref.watch(usuariosActivosProvider).maybeWhen(
          data: (u) => u,
          orElse: () => <UsuarioSimple>[],
        );
    final iniciales = _inicialesDeId(widget.tarea.asignadoA, usuarios);

    return Dismissible(
      key: ValueKey('tarea-${widget.tarea.id}'),
      direction: completado
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _toggle();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Completar',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      child: AnimatedOpacity(
        opacity: completado ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 280),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap?.call();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox circular animado
                  GestureDetector(
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, right: 12),
                      child: _toggling
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.0)
                                  .chain(
                                    CurveTween(curve: Curves.elasticOut),
                                  )
                                  .animate(_bounce)
                                  .drive(
                                    Tween(begin: 1.0, end: 1.2),
                                  ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: completado
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: completado
                                        ? AppColors.accent
                                        : AppColors.borderHover,
                                    width: 1.5,
                                  ),
                                ),
                                child: completado
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                    ),
                  ),

                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tarea.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: completado
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: completado
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AreaBadge(area: widget.tarea.area),
                            PrioridadBadge(prioridad: widget.tarea.prioridad),
                            if (fechaStr != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: fechaCol.withValues(
                                    alpha: fechaCol == AppColors.textTertiary
                                        ? 0
                                        : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (fechaIc != null) ...[
                                      Icon(
                                        fechaIc,
                                        size: 11,
                                        color: fechaCol,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      fechaStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: fechaCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Thumbnail de imagen adjunta
                  if (widget.tarea.imagenUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedNetworkImage(
                            imageUrl: widget.tarea.imagenUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.surface2),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surface2,
                              child: Icon(Icons.image_outlined,
                                  size: 16,
                                  color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (iniciales.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 1),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            iniciales,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Chevron navegable explícitamente
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onTap?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

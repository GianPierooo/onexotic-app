import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/disenio.dart';
import '../providers/disenios_provider.dart';
import 'estado_chip.dart';

class DisenioCard extends ConsumerWidget {
  final Disenio disenio;

  const DisenioCard({super.key, required this.disenio});

  String? _formatFecha(DateTime? d) {
    if (d == null) return null;
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hoy = DateTime.now();
    final diff = d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff < 0) return 'Venció';
    if (diff == 0) return 'Vence hoy';
    if (diff == 1) return 'Vence mañana';
    if (diff <= 7) return 'en $diff días';
    return '${d.day} ${meses[d.month - 1]}';
  }

  Color _fechaColor(DateTime? d) {
    if (d == null) return AppColors.textTertiary;
    final hoy = DateTime.now();
    final diff = d.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (diff < 0) return AppColors.error;
    if (diff <= 2) return AppColors.warning;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? '',
      orElse: () => '',
    );
    final isCeo = rol == 'ceo' || rol == 'manager';
    final esRevision = disenio.estado == 'revision';
    final fechaStr = _formatFecha(disenio.fechaLimite);
    final fechaCol = _fechaColor(disenio.fechaLimite);

    return GestureDetector(
      onTap: () => context.push('/disenios/detalle', extra: disenio),
      child: _CardBody(
        disenio: disenio,
        isCeo: isCeo,
        esRevision: esRevision,
        fechaStr: fechaStr,
        fechaCol: fechaCol,
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  final Disenio disenio;
  final bool isCeo;
  final bool esRevision;
  final String? fechaStr;
  final Color fechaCol;

  const _CardBody({
    required this.disenio,
    required this.isCeo,
    required this.esRevision,
    required this.fechaStr,
    required this.fechaCol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fechaStrLocal = fechaStr; // local para field promotion
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esRevision && isCeo
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.border,
          width: esRevision && isCeo ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  titulo: disenio.titulo,
                  version: disenio.version,
                  thumbnailUrl: disenio.thumbnailUrl,
                  estado: disenio.estado,
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disenio.titulo,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disenio.dropNombre ?? 'Sin drop',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          EstadoChip(estado: disenio.estado),
                          if (fechaStrLocal != null)
                            Text(
                              fechaStrLocal,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: fechaCol,
                              ),
                            ),
                        ],
                      ),

                      if (disenio.estado == 'rechazado' &&
                          disenio.feedback != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  disenio.feedback!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isCeo && disenio.estado != 'cancelado') ...[
            Container(height: 0.5, color: AppColors.border),
            _AccionButtonsCeo(disenio: disenio),
          ],
        ],
      ),
    );
  }
}

// ─── Thumbnail con overlay de estado ──────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String titulo;
  final int version;
  final String? thumbnailUrl;
  final String estado;

  const _Thumbnail({
    required this.titulo,
    required this.version,
    this.thumbnailUrl,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final color = EstadoChip.colorForEstado(estado);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          // Fondo con borde de estado
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
                width: 0.5,
              ),
            ),
          ),
          // Imagen o placeholder exactamente cuadrado
          ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: SizedBox(
              width: 64,
              height: 64,
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: color.withValues(alpha: 0.08),
                      ),
                      errorWidget: (_, __, ___) =>
                          _Placeholder(titulo: titulo, color: color),
                    )
                  : _Placeholder(titulo: titulo, color: color),
            ),
          ),
          // Versión badge (top-left)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'v$version',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          // Punto de estado (bottom-right)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String titulo;
  final Color color;
  const _Placeholder({required this.titulo, required this.color});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          titulo.isNotEmpty ? titulo[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

// ─── Botones CEO para todos los estados ───────────────────────────────────────

class _AccionButtonsCeo extends ConsumerWidget {
  final Disenio disenio;
  const _AccionButtonsCeo({required this.disenio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cambiarState = ref.watch(cambiarEstadoProvider);
    final aprobarState = ref.watch(aprobarDisenioProvider);
    final rechazarState = ref.watch(rechazarDisenioProvider);
    final cancelarState = ref.watch(cancelarDisenioProvider);
    final isLoading = cambiarState is AsyncLoading ||
        aprobarState is AsyncLoading ||
        rechazarState is AsyncLoading ||
        cancelarState is AsyncLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: switch (disenio.estado) {
        'brief' => _BotonSimple(
            label: 'Iniciar proceso',
            icon: Icons.play_arrow_rounded,
            color: AppColors.warning,
            loading: isLoading,
            onTap: () async {
              await ref
                  .read(cambiarEstadoProvider.notifier)
                  .cambiar(disenio.id, 'proceso');
            },
          ),
        'proceso' => _BotonSimple(
            label: 'Ver progreso',
            icon: Icons.visibility_outlined,
            color: AppColors.warning,
            loading: false,
            onTap: () => context.push('/disenios/detalle', extra: disenio),
          ),
        'avance' => Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/disenios/detalle', extra: disenio),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    backgroundColor:
                        const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                    foregroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: Text('Ver avance',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        'revision' => Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isLoading ? null : () => _showRechazarDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.45)),
                    backgroundColor: AppColors.error.withValues(alpha: 0.06),
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: Text('Rechazar',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final ok = await ref
                              .read(aprobarDisenioProvider.notifier)
                              .aprobar(disenio.id);
                          if (ok && context.mounted) {
                            _snack(context, 'Diseño aprobado',
                                AppColors.success);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 15),
                  label: Text('Aprobar',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        'rechazado' => _BotonSimple(
            label: 'Reabrir proceso',
            icon: Icons.refresh_rounded,
            color: AppColors.info,
            loading: isLoading,
            onTap: () async {
              await ref
                  .read(cambiarEstadoProvider.notifier)
                  .cambiar(disenio.id, 'proceso');
            },
          ),
        'aprobado' => _BotonSimple(
            label: 'Ver detalle',
            icon: Icons.open_in_new_rounded,
            color: AppColors.success,
            loading: false,
            onTap: () => context.push('/disenios/detalle', extra: disenio),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _showRechazarDialog(BuildContext context, WidgetRef ref) {
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _RechazarDialog(
        feedbackCtrl: feedbackCtrl,
        onConfirm: () async {
          final feedback = feedbackCtrl.text.trim();
          if (feedback.isEmpty) return;
          final ok = await ref
              .read(rechazarDisenioProvider.notifier)
              .rechazar(disenio.id, feedback);
          if (ok && ctx.mounted) {
            Navigator.pop(ctx);
            if (context.mounted) {
              _snack(context, 'Diseño rechazado', AppColors.error);
            }
          }
        },
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }
}

class _BotonSimple extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _BotonSimple({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        icon: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color))
            : Icon(icon, size: 15),
        label: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RechazarDialog extends StatefulWidget {
  final TextEditingController feedbackCtrl;
  final VoidCallback onConfirm;

  const _RechazarDialog({
    required this.feedbackCtrl,
    required this.onConfirm,
  });

  @override
  State<_RechazarDialog> createState() => _RechazarDialogState();
}

class _RechazarDialogState extends State<_RechazarDialog> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.feedbackCtrl.addListener(
      () => setState(
          () => _hasText = widget.feedbackCtrl.text.trim().isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.feedback_outlined,
              color: AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Rechazar diseño',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explica a la diseñadora qué debe corregir.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.feedbackCtrl,
            autofocus: true,
            maxLines: 4,
            cursorColor: AppColors.accent,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ej: Cambiar paleta de colores, el rojo no funciona...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPlaceholder,
              ),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _hasText ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Rechazar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

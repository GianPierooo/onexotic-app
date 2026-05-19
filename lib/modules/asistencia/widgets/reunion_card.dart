import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/asistencia_provider.dart';
import '../providers/reuniones_provider.dart';
import 'miembro_asistencia_item.dart';

class ReunionCard extends ConsumerStatefulWidget {
  final ReunionHoyData data;
  final Reunion? reunion;
  const ReunionCard({super.key, required this.data, this.reunion});

  @override
  ConsumerState<ReunionCard> createState() => _ReunionCardState();
}

class _ReunionCardState extends ConsumerState<ReunionCard> {
  bool _enCurso() {
    final h = DateTime.now().hour;
    return h >= 8 && h < 11;
  }

  String _labelTipo(String tipo) => switch (tipo) {
        'diaria' => 'Reunión diaria',
        'semanal' => 'Reunión semanal',
        'extraordinaria' => 'Reunión extraordinaria',
        _ => 'Reunión',
      };

  String _formatHora(String hora) {
    // 'HH:mm' → '9:00 AM'
    final parts = hora.split(':');
    if (parts.length < 2) return hora;
    final h = int.tryParse(parts[0]) ?? 9;
    final m = parts[1].padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final marcarState = ref.watch(marcarAsistenciaProvider);
    final isLoading = marcarState is AsyncLoading;
    final error = marcarState is AsyncError ? marcarState.error.toString() : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado de la reunión ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _labelTipo(widget.reunion?.tipo ?? 'diaria'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_enCurso()) ...[
                            const SizedBox(width: 8),
                            const _Badge(
                              label: 'EN CURSO',
                              color: AppColors.success,
                            ),
                          ],
                          if (widget.reunion?.esRecurrente == true) ...[
                            const SizedBox(width: 8),
                            _Badge(
                              label: 'Recurrente · ${widget.reunion!.recurrenciaLabel}',
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatHora(widget.reunion?.hora ?? '09:00')} · ${widget.reunion?.lugar ?? 'Showroom'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Contador presentes/total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.data.presentes}/${widget.data.total}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'presentes',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppColors.border),

          // ── Lista de miembros ─────────────────────────────────────────────
          ...widget.data.miembros.asMap().entries.map((entry) {
            final i = entry.key;
            final miembro = entry.value;
            return Column(
              children: [
                MiembroAsistenciaItem(miembro: miembro),
                if (i < widget.data.miembros.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                    indent: 68,
                  ),
              ],
            );
          }),

          // ── Botón marcar asistencia ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            error,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 48,
                  child: widget.data.yaMarque
                      ? _RegistradoButton()
                      : ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => ref
                                  .read(marcarAsistenciaProvider.notifier)
                                  .marcar(reunionId: widget.reunion?.id ?? ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            disabledBackgroundColor:
                                AppColors.accent.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Marcar mi asistencia',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────────

class _RegistradoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            'Asistencia registrada',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

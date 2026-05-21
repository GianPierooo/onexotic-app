import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// MetricCard premium · gradient top-border, icon con glow, counter animado.
///
/// Mejoras visuales v2:
/// - Línea superior con gradiente (valueColor → transparente)
/// - BoxShadow sutil en el contenedor del ícono
/// - Kerning -1.5 en los valores grandes (Space Grotesk se ve mejor)
/// - Hover sutil al press con scale 0.97
class MetricCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final String badge;
  final Color valueColor;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.badge,
    required this.valueColor,
    this.onTap,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _pressed = false;

  /// Si el valor es puramente numérico, retorna el int para counter animado.
  int? get _numericValue {
    final m = RegExp(r'^(\d+)$').firstMatch(widget.value);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  Widget _buildCard() {
    final num = _numericValue;
    final bg = _pressed ? AppColors.surface2 : AppColors.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient top-border ────────────────────────────────────
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.valueColor.withValues(alpha: 0.7),
                    widget.valueColor.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Contenido de la card ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícono con glow sutil
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: widget.valueColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: widget.valueColor.withValues(alpha: 0.20),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.valueColor,
                        ),
                      ),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.badge.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Valor — animado si es numérico
                  if (num != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: num.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        v.round().toString(),
                        style: AppTypography.metricLarge(
                          color: widget.valueColor,
                        ).copyWith(
                          fontSize: 28,
                          letterSpacing: -1.5,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.value,
                      style: AppTypography.metricLarge(
                        color: widget.valueColor,
                      ).copyWith(
                        fontSize: 26,
                        letterSpacing: -1.5,
                      ),
                    ),

                  const SizedBox(height: 5),

                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

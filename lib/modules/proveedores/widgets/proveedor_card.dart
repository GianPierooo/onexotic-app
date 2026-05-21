import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/proveedor.dart';

class ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onTap;
  final int index;

  const ProveedorCard({
    super.key,
    required this.proveedor,
    required this.onTap,
    this.index = 0,
  });

  static IconData _iconForTipo(String? tipo) => switch (tipo) {
        'tela' => Icons.layers_outlined,
        'estampado' => Icons.palette_outlined,
        'confeccion' => Icons.content_cut_rounded,
        'packaging' => Icons.inventory_2_outlined,
        _ => Icons.business_outlined,
      };

  static Color _colorForTipo(String? tipo) => switch (tipo) {
        'tela' => AppColors.info,
        'estampado' => const Color(0xFFA78BFA),
        'confeccion' => AppColors.accent,
        'packaging' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorForTipo(proveedor.tipo);
    final tieneRating = proveedor.rating != null && proveedor.rating! > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: proveedor.activo
                ? AppColors.border
                : AppColors.error.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconForTipo(proveedor.tipo), size: 20, color: color),
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
                          proveedor.nombre,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: proveedor.activo
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!proveedor.activo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'INACTIVO',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          proveedor.tipoLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      if (proveedor.productosAsociados > 0)
                        Text(
                          '${proveedor.productosAsociados} productos',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      if (proveedor.telefono != null)
                        Text(
                          proveedor.telefono!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (tieneRating) ...[
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < proveedor.rating!;
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 12,
                        color: filled
                            ? AppColors.warning
                            : AppColors.textTertiary,
                      );
                    }),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 260.ms, delay: (index * 35).ms, curve: Curves.easeOut)
        .moveY(begin: 6, end: 0, duration: 280.ms, delay: (index * 35).ms);
  }
}

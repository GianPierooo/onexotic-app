import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';
import 'stock_badge.dart';

class TallaChip extends StatelessWidget {
  final Producto variante;
  final bool showStock;

  const TallaChip({super.key, required this.variante, this.showStock = false});

  @override
  Widget build(BuildContext context) {
    final sinStock = variante.stock == 0;
    final color =
        StockBadge.colorForStock(variante.stock, variante.stockMinimo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sinStock
            ? AppColors.surface2.withValues(alpha: 0.4)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sinStock
              ? AppColors.borderSubtle
              : color.withValues(alpha: 0.32),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            variante.talla,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: sinStock
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
              letterSpacing: 0.4,
              decoration: sinStock ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textTertiary,
            ),
          ),
          if (showStock && !sinStock) ...[
            const SizedBox(width: 5),
            Text(
              '${variante.stock}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

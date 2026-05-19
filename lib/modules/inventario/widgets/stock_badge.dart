import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockBadge extends StatelessWidget {
  final int stock;
  final int stockMinimo;
  final bool compact;

  const StockBadge({
    super.key,
    required this.stock,
    required this.stockMinimo,
    this.compact = false,
  });

  static Color colorForStock(int stock, int stockMinimo) {
    if (stock == 0) return const Color(0xFF555555);
    if (stock <= stockMinimo) return const Color(0xFFEF4444);
    if (stock <= 10) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForStock(stock, stockMinimo);
    final isAgotado = stock == 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAgotado ? 'AGOTADO' : '$stock',
            style: GoogleFonts.spaceGrotesk(
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
          if (!isAgotado && !compact) ...[
            const SizedBox(height: 1),
            Text(
              'uds',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

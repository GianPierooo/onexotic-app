import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class RatingSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;

  const RatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Calificación',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(5, (i) {
              final star = i + 1;
              final isFilled = value != null && value! >= star;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Tap en la estrella ya activa la deselecciona.
                  onChanged(value == star ? null : star);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isFilled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 30,
                    color: isFilled
                        ? AppColors.warning
                        : AppColors.textTertiary,
                  ),
                ),
              );
            }),
            const Spacer(),
            if (value != null)
              Text(
                _labelFor(value!),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _labelFor(int rating) => switch (rating) {
        1 => 'Muy malo',
        2 => 'Malo',
        3 => 'Regular',
        4 => 'Bueno',
        5 => 'Excelente',
        _ => '',
      };
}

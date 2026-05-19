import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Avatar con iniciales o imagen · anillo sutil + online indicator opcional.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.nombre,
    this.imageUrl,
    this.size = 40,
    this.online = false,
    this.color,
  });

  final String nombre;
  final String? imageUrl;
  final double size;
  final bool online;
  final Color? color;

  String get _initials {
    final parts = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  Color _fallbackColor() {
    if (color != null) return color!;
    final hash = nombre.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      AppColors.areaTech,
      AppColors.areaDisenio,
      AppColors.areaMarketing,
      AppColors.areaProduccion,
      AppColors.areaRRHH,
      AppColors.accent,
    ];
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = _fallbackColor();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg.withValues(alpha: 0.15),
              border: Border.all(
                color: bg.withValues(alpha: 0.35),
                width: 1,
              ),
              image: imageUrl != null && imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Text(
                    _initials,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w600,
                      color: bg,
                    ),
                  )
                : null,
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

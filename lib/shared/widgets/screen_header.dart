import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Header custom de pantalla · 28px título w600, subtítulo 14px #888.
///
/// Reemplaza al AppBar de Material. Usar dentro de Column/SliverList.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 16),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.screenTitle(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.screenSubtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Etiqueta de sección con línea accent naranja · estilo OnExotic premium.
///
/// Reemplaza los labels de sección de texto plano tipo "RESUMEN", "ACCESO RÁPIDO".
/// La línea naranja de 14×2px ancla la jerarquía visual sin añadir ruido.
///
/// Uso:
/// ```dart
/// SectionLabel('RESUMEN')
/// SectionLabel('MIS DISEÑOS ACTIVOS', trailing: TextButton(...))
/// ```
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String text;

  /// Widget opcional a la derecha (ej: "Ver todos" TextButton).
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Línea accent naranja
          Container(
            width: 14,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          // Texto de sección
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.9,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Botón circular sutil para top bars (notificaciones, back, etc).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

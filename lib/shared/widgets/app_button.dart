import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

/// Botón OnExotic · height 52, radius 12, sin sombras, con scale al press.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.fullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool fullWidth;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  ({Color bg, Color fg, Border? border}) _colors() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (bg: AppColors.accent, fg: Colors.white, border: null);
      case AppButtonVariant.secondary:
        return (
          bg: Colors.transparent,
          fg: AppColors.textPrimary,
          border: Border.all(color: AppColors.border, width: 1),
        );
      case AppButtonVariant.destructive:
        return (
          bg: Colors.transparent,
          fg: AppColors.error,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        );
      case AppButtonVariant.ghost:
        return (
          bg: Colors.transparent,
          fg: AppColors.textSecondary,
          border: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final disabled = widget.onPressed == null || widget.loading;

    final child = Container(
      height: widget.height,
      width: widget.fullWidth ? double.infinity : null,
      padding: widget.fullWidth
          ? null
          : const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: disabled ? c.bg.withValues(alpha: 0.5) : c.bg,
        borderRadius: BorderRadius.circular(12),
        border: c.border,
      ),
      alignment: Alignment.center,
      child: widget.loading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(c.fg),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: c.fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTypography.buttonPrimary(color: c.fg),
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    offset: _pressed ? const Offset(0.15, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Icon(widget.trailingIcon, size: 18, color: c.fg),
                  ),
                ],
              ],
            ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

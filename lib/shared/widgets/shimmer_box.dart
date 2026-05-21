import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Bloque shimmer reutilizable · se adapta automáticamente al tema (dark/light).
///
/// Uso básico:
/// ```dart
/// ShimmerBox(width: double.infinity, height: 60, radius: 12)
/// ```
///
/// Para loading states complejos, usa los helpers de esta misma librería:
/// - [ShimmerMetricGrid] — 2×2 grid de métrica cards
/// - [ShimmerListItem]  — fila de lista genérica (avatar + texto)
/// - [ShimmerCard]      — card con altura custom
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores de shimmer calibrados para el tema OnExotic
    final baseColor   = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers de skeleton compuestos
// ──────────────────────────────────────────────────────────────────────────────

/// Grid 2×2 de MetricCard skeletons — reemplaza _MetricasLoading del dashboard.
class ShimmerMetricGrid extends StatelessWidget {
  const ShimmerMetricGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _MetricSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _MetricSkeleton()),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricSkeleton()),
          const SizedBox(width: 12),
          Expanded(child: _MetricSkeleton()),
        ]),
      ],
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE);
    final highlight = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  width: 36,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de fila de lista: avatar circular + dos líneas de texto.
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key, this.hasAvatar = true});

  final bool hasAvatar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE);
    final highlight = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            if (hasAvatar) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de card genérico con altura custom.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 80, this.radius = 16});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE);
    final highlight = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
      ),
    );
  }
}

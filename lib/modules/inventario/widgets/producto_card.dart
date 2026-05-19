import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';
import 'stock_badge.dart';
import 'talla_chip.dart';

class ProductoCard extends StatelessWidget {
  final List<Producto> variantes;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductoCard({
    super.key,
    required this.variantes,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (variantes.isEmpty) return const SizedBox.shrink();
    final principal = variantes.first;
    final stockTotal = variantes.fold(0, (sum, p) => sum + p.stock);
    final stockMin = principal.stockMinimo;
    final hayCritico = variantes.any((p) => p.esCritico || p.esAgotado);
    final showMenu = onEdit != null || onDelete != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hayCritico
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              _Thumbnail(
                nombre: principal.nombre,
                imagenUrl: principal.imagenUrl,
                tipo: principal.tipo,
              ),
              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      principal.nombre,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        Producto.labelTipo(principal.tipo),
                        if (principal.dropNombre != null) principal.dropNombre!,
                      ].join(' · '),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (principal.sku != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        principal.sku!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: variantes
                            .map((v) => Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: TallaChip(variante: v),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Derecha: menú + stock ──────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showMenu)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert_rounded,
                            size: 16, color: AppColors.textTertiary),
                        color: AppColors.surface3,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        itemBuilder: (_) => [
                          if (onEdit != null)
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 15,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Text('Editar',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 15, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Text('Eliminar',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.error)),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') onDelete?.call();
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: showMenu ? 4 : 2, left: 8),
                    child: StockBadge(
                      stock: stockTotal,
                      stockMinimo: stockMin * variantes.length,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Thumbnail cuadrado ───────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String nombre;
  final String? imagenUrl;
  final String tipo;

  const _Thumbnail({
    required this.nombre,
    this.imagenUrl,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagenUrl != null
            ? CachedNetworkImage(
                imageUrl: imagenUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _loadingPlaceholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 22, color: AppColors.textTertiary),
          const SizedBox(height: 2),
          Text(
            nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: AppColors.surface2,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../widgets/stock_badge.dart';
import '../widgets/talla_chip.dart';

class ProductoDetailScreen extends ConsumerWidget {
  final List<Producto> variantes;

  const ProductoDetailScreen({super.key, required this.variantes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (variantes.isEmpty) return const SizedBox.shrink();
    final p = variantes.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inventario');
            }
          },
        ),
        title: Text(
          p.nombre,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen / placeholder grande ──────────────────────────────
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: p.imagenUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CachedNetworkImage(
                        imageUrl: p.imagenUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(p),
                      ),
                    )
                  : _placeholder(p),
            ),
            const SizedBox(height: 20),

            // ── Info básica ──────────────────────────────────────────────
            Text(
              p.nombre,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _InfoChip(Producto.labelTipo(p.tipo)),
                const SizedBox(width: 8),
                if (p.dropNombre != null) _InfoChip(p.dropNombre!),
                if (p.color != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(p.color!),
                ],
              ],
            ),
            if (p.sku != null) ...[
              const SizedBox(height: 6),
              Text(
                'SKU: ${p.sku}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Stock por talla ──────────────────────────────────────────
            const _Label('STOCK POR TALLA'),
            const SizedBox(height: 12),
            ...variantes.map((v) => _TallaStockRow(variante: v, ref: ref)),

            const SizedBox(height: 24),

            // ── Precios (CEO / Producción) ─────────────────────────────
            if (p.costo != null || p.precioVenta != null) ...[
              const _Label('PRECIOS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (p.costo != null)
                    Expanded(
                      child: _PrecioCard(
                        label: 'Costo',
                        valor: 'S/ ${p.costo!.toStringAsFixed(2)}',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (p.costo != null && p.precioVenta != null)
                    const SizedBox(width: 8),
                  if (p.precioVenta != null)
                    Expanded(
                      child: _PrecioCard(
                        label: 'Precio venta',
                        valor: 'S/ ${p.precioVenta!.toStringAsFixed(2)}',
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
              if (p.costo != null && p.precioVenta != null) ...[
                const SizedBox(height: 8),
                _PrecioCard(
                  label: 'Margen',
                  valor:
                      '${(((p.precioVenta! - p.costo!) / p.precioVenta!) * 100).toStringAsFixed(1)}%',
                  color: AppColors.info,
                  fullWidth: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Producto p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(
            p.nombre,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de talla + stock + editar ──────────────────────────────────────────

class _TallaStockRow extends ConsumerStatefulWidget {
  final Producto variante;
  final WidgetRef ref;

  const _TallaStockRow({required this.variante, required this.ref});

  @override
  ConsumerState<_TallaStockRow> createState() => _TallaStockRowState();
}

class _TallaStockRowState extends ConsumerState<_TallaStockRow> {
  bool _editando = false;
  late int _stock;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _stock = widget.variante.stock;
    _ctrl = TextEditingController(text: '$_stock');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variante;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          TallaChip(variante: v),
          const SizedBox(width: 12),
          Expanded(
            child: _editando
                ? SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: AppColors.accent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: AppColors.accent),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          StockBadge(stock: v.stock, stockMinimo: v.stockMinimo),
          const SizedBox(width: 8),
          if (!_editando)
            GestureDetector(
              onTap: () => setState(() => _editando = true),
              child: Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textTertiary),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _editando = false),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final nuevo = int.tryParse(_ctrl.text.trim()) ?? v.stock;
                    await ref
                        .read(editarStockProvider.notifier)
                        .actualizar(v.id, nuevo);
                    if (mounted) setState(() => _editando = false);
                  },
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.success),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Widgets de soporte ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _PrecioCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final bool fullWidth;

  const _PrecioCard({
    required this.label,
    required this.valor,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    return widget;
  }
}

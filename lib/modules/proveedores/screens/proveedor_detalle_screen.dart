import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/proveedor.dart';
import '../providers/proveedores_provider.dart';
import 'proveedor_form_sheet.dart';

class ProveedorDetalleScreen extends ConsumerWidget {
  final Proveedor proveedor;
  const ProveedorDetalleScreen({super.key, required this.proveedor});

  Future<void> _editar(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProveedorFormSheet(proveedor: proveedor),
    );
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Desactivar proveedor',
          style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Desactivar a "${proveedor.nombre}"? Los productos asociados conservarán la referencia pero el proveedor quedará oculto en filtros.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Desactivar',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(gestionarProveedorProvider.notifier)
        .eliminar(proveedor.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync =
        ref.watch(productosDeProveedorProvider(proveedor.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Proveedor',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _editar(context),
            icon: Icon(Icons.edit_outlined,
                color: AppColors.textPrimary, size: 20),
          ),
          IconButton(
            onPressed: () => _eliminar(context, ref),
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Header(proveedor: proveedor),
          const SizedBox(height: 24),
          _InfoBlock(proveedor: proveedor),
          const SizedBox(height: 24),
          _SectionLabel('PRODUCTOS ASOCIADOS'),
          const SizedBox(height: 10),
          productosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
            ),
            error: (e, _) => _EmptyBlock('Error cargando productos'),
            data: (productos) => productos.isEmpty
                ? _EmptyBlock(
                    'Aún no hay productos asociados a este proveedor')
                : Column(
                    children: productos
                        .map((p) => _ProductoMiniItem(producto: p))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Proveedor proveedor;
  const _Header({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_outlined,
                    size: 28, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proveedor.tipoLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (proveedor.rating != null && proveedor.rating! > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (i) {
                final filled = i < proveedor.rating!;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color:
                        filled ? AppColors.warning : AppColors.textTertiary,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final Proveedor proveedor;
  const _InfoBlock({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[];
    if (proveedor.contacto != null) {
      rows.add((Icons.person_outline_rounded, 'Contacto', proveedor.contacto!));
    }
    if (proveedor.telefono != null) {
      rows.add((Icons.phone_outlined, 'Teléfono', proveedor.telefono!));
    }
    if (proveedor.notas != null) {
      rows.add((Icons.notes_rounded, 'Notas', proveedor.notas!));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: rows.map((r) {
          final (icon, label, value) = r;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductoMiniItem extends StatelessWidget {
  final Map<String, dynamic> producto;
  const _ProductoMiniItem({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto['nombre'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${producto['tipo'] ?? ''} · ${producto['talla'] ?? ''} · ${producto['sku'] ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${producto['stock'] ?? 0}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

class _EmptyBlock extends StatelessWidget {
  final String mensaje;
  const _EmptyBlock(this.mensaje);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

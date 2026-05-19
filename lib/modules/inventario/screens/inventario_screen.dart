import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../widgets/alerta_stock_banner.dart';
import '../widgets/drop_filter_pills.dart';
import '../widgets/producto_card.dart';
import 'agregar_producto_bottom_sheet.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({List<Producto>? variantesToEdit}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AgregarProductoBottomSheet(
          variantesToEdit: variantesToEdit,
        ),
      );
    });
  }

  void _confirmarEliminar(List<Producto> variantes) {
    final count = variantes.length;
    final nombre = variantes.first.nombre;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showDialog(
        context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Eliminar producto',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        content: Text(
          'Se eliminará "$nombre" (${count == 1 ? '1 variante' : '$count variantes'}). Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ids = variantes.map((v) => v.id).toList();
              final ok = await ref
                  .read(gestionarProductoProvider.notifier)
                  .eliminar(ids);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Producto eliminado',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 13)),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: Text('Eliminar',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          ),
        ],
      ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventarioAsync = ref.watch(inventarioAgrupadoProvider);
    final totalAsync = ref.watch(inventarioProvider);
    final soloCriticos = ref.watch(soloCriticosProvider);
    final totalSkus =
        totalAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: AppColors.accent,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'inventario',
            slides: GuiasContent.inventario,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (context.canPop()) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventario',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$totalSkus SKUs',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const GuiaHelpButton(slides: GuiasContent.inventario),
                  if (soloCriticos)
                    GestureDetector(
                      onTap: () {
                        ref.read(soloCriticosProvider.notifier).state = false;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('Críticos',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.error)),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded,
                                size: 12, color: AppColors.error),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Buscador ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o SKU...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textTertiary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textTertiary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const DropFilterPills(),
            const SizedBox(height: 12),
            const AlertaStockBanner(),

            // ── Lista de productos ────────────────────────────────────────
            Expanded(
              child: inventarioAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
                error: (e, _) => _ErrorCard('$e'),
                data: (grupos) {
                  if (grupos.isEmpty) {
                    return _EmptyState(buscando: _searchCtrl.text.isNotEmpty);
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface2,
                    onRefresh: () async => ref.invalidate(inventarioProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: grupos.length,
                      itemBuilder: (_, i) {
                        final grupo = grupos[i];
                        return ProductoCard(
                          key: ValueKey(grupo.first.id),
                          variantes: grupo,
                          onTap: () => context.push(
                            '/inventario/detalle',
                            extra: grupo,
                          ),
                          onEdit: () => _abrirFormulario(
                              variantesToEdit: grupo),
                          onDelete: () => _confirmarEliminar(grupo),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool buscando;
  const _EmptyState({required this.buscando});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            buscando
                ? 'No se encontraron productos'
                : 'No hay productos · Toca + para agregar',
            style: GoogleFonts.inter(
                fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

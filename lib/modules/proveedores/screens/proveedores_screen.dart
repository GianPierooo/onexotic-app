import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/proveedor.dart';
import '../providers/proveedores_provider.dart';
import '../widgets/proveedor_card.dart';
import 'proveedor_detalle_screen.dart';
import 'proveedor_form_sheet.dart';

class ProveedoresScreen extends ConsumerWidget {
  const ProveedoresScreen({super.key});

  Future<void> _abrirCrear(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProveedorFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proveedoresAsync = ref.watch(proveedoresProvider);
    final tipo = ref.watch(filtroTipoProveedorProvider);
    final inactivos = ref.watch(mostrarInactivosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Proveedores',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: inactivos ? 'Ocultar inactivos' : 'Mostrar inactivos',
            onPressed: () =>
                ref.read(mostrarInactivosProvider.notifier).state = !inactivos,
            icon: Icon(
              inactivos
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: inactivos ? AppColors.accent : AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _FilterPills(activo: tipo),
          const SizedBox(height: 6),
          Expanded(
            child: proveedoresAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
              error: (e, _) => _ErrorView(
                mensaje: e.toString(),
                onReintentar: () => ref.invalidate(proveedoresProvider),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return _EmptyState(
                    onCrear: () => _abrirCrear(context),
                    filtrado: tipo != null,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface2,
                  onRefresh: () async {
                    ref.invalidate(proveedoresProvider);
                    await ref
                        .read(proveedoresProvider.future)
                        .catchError((_) => <Proveedor>[]);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => ProveedorCard(
                      proveedor: lista[i],
                      index: i,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProveedorDetalleScreen(proveedor: lista[i]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => _abrirCrear(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

class _FilterPills extends ConsumerWidget {
  final String? activo;
  const _FilterPills({required this.activo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <(String?, String)>[
      (null, 'Todos'),
      ...Proveedor.tiposDisponibles
          .map((e) => (e.$1 as String?, e.$2)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = items[i];
          final isActive = activo == value;
          return GestureDetector(
            onTap: () =>
                ref.read(filtroTipoProveedorProvider.notifier).state = value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  final bool filtrado;
  const _EmptyState({required this.onCrear, this.filtrado = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              filtrado
                  ? 'Sin proveedores de este tipo'
                  : 'Aún no hay proveedores',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (!filtrado) ...[
              const SizedBox(height: 6),
              Text(
                'Agrega tu primer proveedor de tela, estampado,\nconfección o packaging',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCrear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Agregar proveedor',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorView(
      {required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la lista',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Reintentar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/drop.dart';
import '../providers/drops_provider.dart';
import '../providers/inventario_provider.dart';

class DropFilterPills extends ConsumerWidget {
  const DropFilterPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(dropsInventarioProvider);
    final dropActivo = ref.watch(dropFiltroInventarioProvider);

    return drops.when(
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox.shrink(),
      data: (lista) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _Pill(
              label: 'Todos',
              activo: dropActivo == null,
              onTap: () =>
                  ref.read(dropFiltroInventarioProvider.notifier).state = null,
            ),
            const SizedBox(width: 8),
            ...lista.map(
              (d) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DropPill(
                  drop: d,
                  activo: dropActivo == d.id,
                  onTap: () => ref
                      .read(dropFiltroInventarioProvider.notifier)
                      .state = d.id,
                  onLongPress: () => _mostrarMenu(context, ref, d),
                ),
              ),
            ),
            _AddDropPill(onTap: () => _mostrarNuevoDrop(context)),
          ],
        ),
      ),
    );
  }

  // ── Menú contextual del drop ───────────────────────────────────────────────

  void _mostrarMenu(BuildContext context, WidgetRef ref, Drop drop) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) =>
            _DropMenuSheet(drop: drop, outerContext: context, ref: ref),
      );
    });
  }

  // ── Sheet para crear nuevo drop ────────────────────────────────────────────

  void _mostrarNuevoDrop(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _NuevoDropSheet(),
      );
    });
  }
}

// ─── Menú contextual (editar / ver / eliminar) ────────────────────────────────

class _DropMenuSheet extends ConsumerWidget {
  final Drop drop;
  final BuildContext outerContext;
  final WidgetRef ref;
  const _DropMenuSheet(
      {required this.drop,
      required this.outerContext,
      required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text(
              drop.nombre,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (drop.estado != null) ...[
              const SizedBox(height: 2),
              Text(
                _labelEstado(drop.estado!),
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            // Editar
            _MenuOption(
              icon: Icons.edit_outlined,
              label: 'Editar drop',
              onTap: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!outerContext.mounted) return;
                  showModalBottomSheet(
                    context: outerContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _EditarDropSheet(drop: drop),
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            // Ver productos
            _MenuOption(
              icon: Icons.inventory_2_outlined,
              label: 'Ver productos de este drop',
              onTap: () {
                Navigator.pop(context);
                ref.read(dropFiltroInventarioProvider.notifier).state = drop.id;
              },
            ),
            const SizedBox(height: 8),
            // Eliminar
            _MenuOption(
              icon: Icons.delete_outline_rounded,
              label: 'Eliminar drop',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await _intentarEliminar(outerContext, ref, drop);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _labelEstado(String e) => switch (e) {
        'planificacion' => 'En planificación',
        'produccion' => 'En producción',
        'lanzado' => 'Lanzado',
        'agotado' => 'Agotado',
        _ => e,
      };

  Future<void> _intentarEliminar(
      BuildContext context, WidgetRef ref, Drop drop) async {
    final count = await contarProductosDelDrop(drop.id);
    if (!context.mounted) return;

    if (count > 0) {
      // No se puede eliminar: tiene productos
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('No se puede eliminar',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          content: Text(
            'El drop "${drop.nombre}" tiene $count ${count == 1 ? 'producto' : 'productos'} asociados. Primero elimina los productos.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Entendido',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.accent)),
            ),
          ],
        ),
      );
      return;
    }

    // Primera confirmación
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Eliminar "${drop.nombre}"',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'El drop será eliminado permanentemente.',
          style:
              GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Continuar',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning))),
        ],
      ),
    );
    if (primera != true || !context.mounted) return;

    // Segunda confirmación
    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('¿Confirmar eliminación?',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error)),
        content: Text('Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error))),
        ],
      ),
    );
    if (segunda != true || !context.mounted) return;

    if (ref.read(dropFiltroInventarioProvider) == drop.id) {
      ref.read(dropFiltroInventarioProvider.notifier).state = null;
    }

    final ok = await ref.read(gestionarDropsProvider.notifier).eliminar(drop.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Drop eliminado' : 'Error al eliminar',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // El color por defecto se resuelve en build (no se puede usar AppColors.textPrimary
    // como default-value porque es un getter dinámico).
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c)),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet: editar drop ───────────────────────────────────────────────────────

class _EditarDropSheet extends ConsumerStatefulWidget {
  final Drop drop;
  const _EditarDropSheet({required this.drop});

  @override
  ConsumerState<_EditarDropSheet> createState() => _EditarDropSheetState();
}

class _EditarDropSheetState extends ConsumerState<_EditarDropSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _conceptoCtrl;
  late String _estado;
  DateTime? _fechaLanzamiento;

  static const _estados = [
    ('planificacion', 'Planificación'),
    ('produccion', 'Producción'),
    ('lanzado', 'Lanzado'),
    ('agotado', 'Agotado'),
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.drop.nombre);
    _conceptoCtrl =
        TextEditingController(text: widget.drop.concepto ?? '');
    _estado = widget.drop.estado ?? 'planificacion';
    _fechaLanzamiento = widget.drop.fechaLanzamiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(gestionarDropsProvider.notifier).editar(
          widget.drop.id,
          nombre: _nombreCtrl.text,
          estado: _estado,
          concepto: _conceptoCtrl.text.trim().isEmpty
              ? null
              : _conceptoCtrl.text.trim(),
          fechaLanzamiento: _fechaLanzamiento,
        );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Drop actualizado',
            style:
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLanzamiento ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaLanzamiento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(gestionarDropsProvider) is AsyncLoading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Editar drop',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nombre
            _label('Nombre *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nombreCtrl,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              decoration: _deco('Ej: Drop 004'),
            ),
            const SizedBox(height: 14),

            // Estado + Fecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Estado *'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _estado,
                        dropdownColor: AppColors.surface2,
                        iconEnabledColor: AppColors.textTertiary,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary),
                        items: _estados
                            .map((e) => DropdownMenuItem(
                                  value: e.$1,
                                  child: Text(e.$2,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _estado = v ?? 'planificacion'),
                        decoration: _deco('Estado'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Fecha lanzamiento'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickFecha,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fechaLanzamiento != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_fechaLanzamiento!)
                                      : 'dd/mm/aaaa',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _fechaLanzamiento != null
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Concepto
            _label('Concepto (opcional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _conceptoCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: _deco('Idea o descripción del drop'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Guardar cambios',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );
}

// ─── Sheet: crear nuevo drop ──────────────────────────────────────────────────

class _NuevoDropSheet extends ConsumerStatefulWidget {
  const _NuevoDropSheet();

  @override
  ConsumerState<_NuevoDropSheet> createState() => _NuevoDropSheetState();
}

class _NuevoDropSheetState extends ConsumerState<_NuevoDropSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  String _estado = 'planificacion';

  static const _estados = [
    ('planificacion', 'Planificación'),
    ('produccion', 'Producción'),
    ('lanzado', 'Lanzado'),
    ('agotado', 'Agotado'),
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(gestionarDropsProvider.notifier).crear(
          nombre: _nombreCtrl.text,
          estado: _estado,
          concepto: _conceptoCtrl.text.trim().isEmpty
              ? null
              : _conceptoCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Drop creado',
            style:
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(gestionarDropsProvider) is AsyncLoading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Nuevo drop',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label('Nombre *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nombreCtrl,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              decoration: _deco('Ej: Drop 004, Verano 2026'),
            ),
            const SizedBox(height: 14),
            _label('Estado'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _estado,
              dropdownColor: AppColors.surface2,
              iconEnabledColor: AppColors.textTertiary,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              items: _estados
                  .map((e) => DropdownMenuItem(
                        value: e.$1,
                        child: Text(e.$2,
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppColors.textPrimary)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _estado = v ?? 'planificacion'),
              decoration: _deco('Estado'),
            ),
            const SizedBox(height: 14),
            _label('Concepto (opcional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _conceptoCtrl,
              maxLines: 2,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: _deco('Idea o descripción del drop'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Crear drop',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );
}

// ─── Pills ────────────────────────────────────────────────────────────────────

class _DropPill extends StatelessWidget {
  final Drop drop;
  final bool activo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DropPill({
    required this.drop,
    required this.activo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          drop.nombre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: activo ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AddDropPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddDropPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('Nuevo drop',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../models/brief.dart';
import '../models/disenio.dart';
import '../providers/historial_provider.dart';

const _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const _tipos = ['polo', 'short', 'pantalon', 'polera', 'accesorio'];

class CrearProductoDesdeDisenioSheet extends ConsumerStatefulWidget {
  final Disenio disenio;
  final Brief? brief;

  const CrearProductoDesdeDisenioSheet({
    super.key,
    required this.disenio,
    this.brief,
  });

  @override
  ConsumerState<CrearProductoDesdeDisenioSheet> createState() =>
      _CrearProductoDesdeDisenioSheetState();
}

class _CrearProductoDesdeDisenioSheetState
    extends ConsumerState<CrearProductoDesdeDisenioSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _colorCtrl;
  final TextEditingController _costoCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  final TextEditingController _stockMinimoCtrl =
      TextEditingController(text: '5');

  String _tipo = 'polo';
  late final Map<String, TextEditingController> _tallaCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.disenio.titulo);
    final primerColor =
        (widget.brief?.colores.isNotEmpty ?? false) ? widget.brief!.colores.first : '';
    _colorCtrl = TextEditingController(text: primerColor);
    _tallaCtrl = {
      for (final t in _tallas) t: TextEditingController(text: '0'),
    };
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _colorCtrl.dispose();
    _costoCtrl.dispose();
    _precioCtrl.dispose();
    _stockMinimoCtrl.dispose();
    for (final c in _tallaCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    final costo =
        double.tryParse(_costoCtrl.text.replaceAll(',', '.')) ?? 0;
    final precio =
        double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0;
    final hayTallas = _tallaCtrl.values
        .any((c) => (int.tryParse(c.text) ?? 0) > 0);
    return _nombreCtrl.text.trim().isNotEmpty &&
        _colorCtrl.text.trim().isNotEmpty &&
        costo > 0 &&
        precio > 0 &&
        hayTallas;
  }

  Future<void> _guardar() async {
    if (!_isValid) return;
    final costo =
        double.parse(_costoCtrl.text.replaceAll(',', '.'));
    final precio =
        double.parse(_precioCtrl.text.replaceAll(',', '.'));
    final stockMinimo = int.tryParse(_stockMinimoCtrl.text) ?? 5;
    final tallaStock = <String, int>{};
    for (final e in _tallaCtrl.entries) {
      final v = int.tryParse(e.value.text) ?? 0;
      if (v > 0) tallaStock[e.key] = v;
    }

    final ok = await ref.read(gestionarProductoProvider.notifier).agregarMultiples(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          dropId: widget.disenio.dropId,
          color: _colorCtrl.text.trim(),
          stockMinimo: stockMinimo,
          costo: costo,
          precioVenta: precio,
          imagenUrl: widget.disenio.thumbnailUrl,
          tallaStock: tallaStock,
          disenioId: widget.disenio.id,
        );

    if (!mounted) return;

    if (ok) {
      await registrarHistorial(
        disenioId: widget.disenio.id,
        accion: 'Agregado a inventario: ${tallaStock.length} talla${tallaStock.length == 1 ? '' : 's'}',
        usuarioId: Supabase.instance.client.auth.currentUser?.id,
      );
      ref.invalidate(historialDeDisenioProvider(widget.disenio.id));
      ref.invalidate(productosDeDisenioProvider(widget.disenio.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Producto creado en inventario',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.of(context).pop(true);
      }
    } else {
      final errState = ref.read(gestionarProductoProvider);
      final msg = errState.maybeWhen(
        error: (e, _) {
          final s = e.toString();
          if (s.contains('disenio_id') || s.contains('column')) {
            return 'Falta columna disenio_id en tabla productos.\n'
                'Ejecuta la migración SQL en Supabase Dashboard.';
          }
          if (s.contains('42501') || s.contains('permission denied') ||
              s.contains('RLS')) {
            return 'Sin permisos para crear producto.\n'
                'Revisa políticas RLS de la tabla productos.';
          }
          return 'Error al guardar: $s';
        },
        orElse: () => 'No se pudo guardar el producto. Inténtalo de nuevo.',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(gestionarProductoProvider) is AsyncLoading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('Crear en inventario',
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
            ]),
            const SizedBox(height: 20),

            // Drop asociado (info, no editable)
            if (widget.disenio.dropNombre != null) ...[
              const _Label('DROP'),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(widget.disenio.dropNombre!,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ),
              const SizedBox(height: 16),
            ],

            // Nombre
            const _Label('NOMBRE *'),
            const SizedBox(height: 6),
            _Input(controller: _nombreCtrl, hint: 'Nombre del producto'),
            const SizedBox(height: 16),

            // Tipo
            const _Label('TIPO *'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tipos.map((t) {
                  final selected = _tipo == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selected ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _labelTipo(t),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Color
            const _Label('COLOR *'),
            const SizedBox(height: 6),
            _Input(
                controller: _colorCtrl,
                hint: 'Ej: Negro, Blanco, Verde oliva...'),
            const SizedBox(height: 16),

            // Tallas y stock
            const _Label('TALLAS Y STOCK'),
            const SizedBox(height: 4),
            Text('Llena solo las tallas que vas a producir',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 10),
            _TallasGrid(tallaCtrl: _tallaCtrl),
            const SizedBox(height: 16),

            // Stock mínimo
            const _Label('STOCK MÍNIMO POR TALLA'),
            const SizedBox(height: 6),
            SizedBox(
              width: 100,
              child: _Input(
                  controller: _stockMinimoCtrl,
                  hint: '5',
                  numericOnly: true),
            ),
            const SizedBox(height: 16),

            // Costo y precio
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('COSTO UNITARIO *'),
                    const SizedBox(height: 6),
                    _Input(
                        controller: _costoCtrl,
                        hint: '0.00',
                        numericOnly: true,
                        prefix: 'S/ '),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('PRECIO VENTA *'),
                    const SizedBox(height: 6),
                    _Input(
                        controller: _precioCtrl,
                        hint: '0.00',
                        numericOnly: true,
                        prefix: 'S/ '),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Botón guardar
            StatefulBuilder(
              builder: (_, setS) {
                for (final c in [
                  _nombreCtrl,
                  _colorCtrl,
                  _costoCtrl,
                  _precioCtrl
                ]) {
                  c.addListener(() => setS(() {}));
                }
                for (final c in _tallaCtrl.values) {
                  c.addListener(() => setS(() {}));
                }
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_isValid && !isSaving) ? _guardar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor:
                          AppColors.success.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.inventory_2_rounded, size: 18),
                    label: Text(
                        isSaving ? 'Guardando...' : 'Guardar en inventario',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _labelTipo(String t) => switch (t) {
        'polo'      => 'Polo',
        'short'     => 'Short',
        'pantalon'  => 'Pantalón',
        'polera'    => 'Polera',
        'accesorio' => 'Accesorio',
        _           => t,
      };
}

// ─── Grid de tallas ───────────────────────────────────────────────────────────

class _TallasGrid extends StatelessWidget {
  final Map<String, TextEditingController> tallaCtrl;
  const _TallasGrid({required this.tallaCtrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tallas.map((t) {
        final ctrl = tallaCtrl[t]!;
        return Container(
          width: 80,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(t,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: ctrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Widgets de soporte ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 0.8));
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool numericOnly;
  final String? prefix;

  const _Input({
    required this.controller,
    required this.hint,
    this.numericOnly = false,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numericOnly
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numericOnly
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))]
          : null,
      style:
          GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

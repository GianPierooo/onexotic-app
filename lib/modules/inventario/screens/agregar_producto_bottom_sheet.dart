import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/producto.dart';
import '../providers/drops_provider.dart';
import '../providers/inventario_provider.dart';

class AgregarProductoBottomSheet extends ConsumerStatefulWidget {
  /// null → modo crear. Lista → modo editar (todas las variantes del grupo).
  final List<Producto>? variantesToEdit;
  const AgregarProductoBottomSheet({super.key, this.variantesToEdit});

  @override
  ConsumerState<AgregarProductoBottomSheet> createState() =>
      _AgregarProductoBottomSheetState();
}

class _AgregarProductoBottomSheetState
    extends ConsumerState<AgregarProductoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController(text: '5');
  final _costoCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();

  static const _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _tipos = [
    ('polo', 'Polo'),
    ('short', 'Short'),
    ('pantalon', 'Pantalón'),
    ('polera', 'Polera'),
    ('accesorio', 'Accesorio'),
  ];

  // Un controller de stock por talla
  late final Map<String, TextEditingController> _tallaStockCtrls;

  String? _selectedTipo;
  String? _selectedDropId;
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _isUploading = false;

  bool get _isEditing => widget.variantesToEdit != null;

  @override
  void initState() {
    super.initState();
    // Inicializar controllers de talla con 0
    _tallaStockCtrls = {
      for (final t in _tallas) t: TextEditingController(text: '0'),
    };

    if (_isEditing) {
      final first = widget.variantesToEdit!.first;
      _nombreCtrl.text = first.nombre;
      _colorCtrl.text = first.color ?? '';
      _stockMinimoCtrl.text = first.stockMinimo.toString();
      _costoCtrl.text = first.costo?.toStringAsFixed(2) ?? '';
      _precioVentaCtrl.text = first.precioVenta?.toStringAsFixed(2) ?? '';
      _selectedTipo = first.tipo;
      _selectedDropId = first.dropId;
      // Pre-cargar stock por talla de los existentes
      for (final variante in widget.variantesToEdit!) {
        _tallaStockCtrls[variante.talla]?.text = variante.stock.toString();
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _colorCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _costoCtrl.dispose();
    _precioVentaCtrl.dispose();
    for (final c in _tallaStockCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Imagen ─────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedFile = file;
        _pickedBytes = bytes;
      });
    } catch (e) {
      if (kDebugMode) print('[image picker] ERROR: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedFile == null || _pickedBytes == null) return null;
    setState(() => _isUploading = true);
    try {
      final ext = _pickedFile!.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('productos').uploadBinary(
            fileName,
            _pickedBytes!,
            fileOptions: FileOptions(contentType: 'image/$ext'),
          );
      return Supabase.instance.client.storage
          .from('productos')
          .getPublicUrl(fileName);
    } catch (e) {
      if (kDebugMode) print('[upload imagen] ERROR: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Recoger tallas con stock > 0
    final tallaStock = <String, int>{};
    for (final talla in _tallas) {
      final v = int.tryParse(_tallaStockCtrls[talla]!.text.trim()) ?? 0;
      if (v > 0) tallaStock[talla] = v;
    }
    if (tallaStock.isEmpty) {
      _showSnackBar('Agrega stock en al menos una talla', isError: true);
      return;
    }

    String? imagenUrl;
    if (_pickedBytes != null) {
      imagenUrl = await _uploadImage();
    } else if (_isEditing) {
      imagenUrl = widget.variantesToEdit?.first.imagenUrl;
    }

    final notifier = ref.read(gestionarProductoProvider.notifier);
    final campos = (
      nombre: _nombreCtrl.text.trim(),
      tipo: _selectedTipo!,
      dropId: _selectedDropId,
      color: _colorCtrl.text.trim(),
      stockMinimo: int.tryParse(_stockMinimoCtrl.text) ?? 5,
      costo: double.tryParse(_costoCtrl.text) ?? 0.0,
      precioVenta: double.tryParse(_precioVentaCtrl.text) ?? 0.0,
      imagenUrl: imagenUrl,
      tallaStock: tallaStock,
    );

    final ok = _isEditing
        ? await notifier.editarMultiples(
            existentes: widget.variantesToEdit!,
            nombre: campos.nombre,
            tipo: campos.tipo,
            dropId: campos.dropId,
            color: campos.color,
            stockMinimo: campos.stockMinimo,
            costo: campos.costo,
            precioVenta: campos.precioVenta,
            imagenUrl: campos.imagenUrl,
            tallaStock: campos.tallaStock,
          )
        : await notifier.agregarMultiples(
            nombre: campos.nombre,
            tipo: campos.tipo,
            dropId: campos.dropId,
            color: campos.color,
            stockMinimo: campos.stockMinimo,
            costo: campos.costo,
            precioVenta: campos.precioVenta,
            imagenUrl: campos.imagenUrl,
            tallaStock: campos.tallaStock,
          );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final err = ref.read(gestionarProductoProvider);
      final msg = err is AsyncError ? err.error.toString() : 'Error al guardar';
      _showSnackBar(msg, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dropsAsync = ref.watch(dropsInventarioProvider);
    final gestionState = ref.watch(gestionarProductoProvider);
    final isSaving = gestionState is AsyncLoading || _isUploading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Editar producto' : 'Agregar producto',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPad),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto
                    _ImagePickerWidget(
                      bytes: _pickedBytes,
                      existingUrl: _isEditing
                          ? widget.variantesToEdit?.first.imagenUrl
                          : null,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    const _FieldLabel('Nombre del producto *'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: _nombreCtrl,
                      hint: 'Ej: Polo Logo ONEXOTIC',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Tipo + Drop
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Tipo *'),
                              const SizedBox(height: 6),
                              _StyledDropdown<String>(
                                value: _selectedTipo,
                                hint: 'Tipo',
                                items: _tipos
                                    .map((t) => DropdownMenuItem(
                                          value: t.$1,
                                          child: Text(t.$2, style: _textStyle),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedTipo = v),
                                validator: (v) =>
                                    v == null ? 'Requerido' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Drop (opcional)'),
                              const SizedBox(height: 6),
                              dropsAsync.when(
                                loading: () => const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                error: (_, __) => const _StyledDropdown<String>(
                                  value: null,
                                  hint: 'Sin Drop',
                                  items: [],
                                  onChanged: null,
                                ),
                                data: (drops) => _StyledDropdown<String>(
                                  value: _selectedDropId,
                                  hint: 'Sin Drop / Exclusivo',
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'Sin Drop',
                                        style: _textStyle.copyWith(
                                            color: AppColors.textTertiary),
                                      ),
                                    ),
                                    ...drops.map((d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text(d.nombre,
                                              style: _textStyle,
                                              overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedDropId = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Color
                    const _FieldLabel('Color *'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: _colorCtrl,
                      hint: 'Ej: Negro, Blanco, Gris',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Tabla de tallas con stock ──────────────────────────
                    const _FieldLabel('TALLAS Y STOCK *'),
                    const SizedBox(height: 8),
                    _TallaStockTable(
                      tallas: _tallas,
                      controllers: _tallaStockCtrls,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo se guardan las tallas con stock > 0',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 14),

                    // Stock mínimo
                    const _FieldLabel('Stock mínimo por talla *'),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: _stockMinimoCtrl,
                      hint: '5',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Precios
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Costo unitario *'),
                              const SizedBox(height: 6),
                              _StyledTextField(
                                controller: _costoCtrl,
                                hint: '0.00',
                                prefixText: 'S/ ',
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Precio de venta *'),
                              const SizedBox(height: 6),
                              _StyledTextField(
                                controller: _precioVentaCtrl,
                                hint: '0.00',
                                prefixText: 'S/ ',
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requerido'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _submit,
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isEditing ? 'Guardar cambios' : 'Agregar producto',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _textStyle =>
      GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary);
}

// ── Tabla tallas + stock ────────────────────────────────────────────────────

class _TallaStockTable extends StatefulWidget {
  final List<String> tallas;
  final Map<String, TextEditingController> controllers;

  const _TallaStockTable({required this.tallas, required this.controllers});

  @override
  State<_TallaStockTable> createState() => _TallaStockTableState();
}

class _TallaStockTableState extends State<_TallaStockTable> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: widget.tallas.asMap().entries.map((entry) {
          final i = entry.key;
          final talla = entry.value;
          final ctrl = widget.controllers[talla]!;
          final stockActual = int.tryParse(ctrl.text) ?? 0;
          final tieneStock = stockActual > 0;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: tieneStock
                      ? AppColors.accent.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(9) : Radius.zero,
                    bottom: i == widget.tallas.length - 1
                        ? const Radius.circular(9)
                        : Radius.zero,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Talla
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: tieneStock
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.surface3,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tieneStock
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          talla,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tieneStock
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Input stock
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tieneStock
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 15, color: AppColors.textTertiary),
                            filled: true,
                            fillColor: tieneStock
                                ? AppColors.surface3
                                : AppColors.surface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: tieneStock
                                    ? AppColors.accent.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.accent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Indicador visual
                      SizedBox(
                        width: 20,
                        child: tieneStock
                            ? const Icon(Icons.check_circle_rounded,
                                size: 16, color: AppColors.success)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < widget.tallas.length - 1)
                Divider(height: 1, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Image picker widget ─────────────────────────────────────────────────────

class _ImagePickerWidget extends StatelessWidget {
  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onTap;

  const _ImagePickerWidget({this.bytes, this.existingUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || existingUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  bytes != null
                      ? Image.memory(bytes!, fit: BoxFit.cover)
                      : Image.network(existingUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder()),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Cambiar',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white)),
                    ),
                  ),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 28, color: AppColors.textTertiary),
        const SizedBox(height: 6),
        Text(
          'Foto del producto (opcional)',
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

// ── Helpers de formulario ───────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.2),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? prefixText;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        prefixStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      onChanged: onChanged,
      items: items,
      dropdownColor: AppColors.surface2,
      iconEnabledColor: AppColors.textTertiary,
      iconDisabledColor: AppColors.textTertiary,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      hint: Text(hint,
          style:
              GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      ),
    );
  }
}

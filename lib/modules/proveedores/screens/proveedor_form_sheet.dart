import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/proveedor.dart';
import '../providers/proveedores_provider.dart';
import '../widgets/rating_selector.dart';

class ProveedorFormSheet extends ConsumerStatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormSheet({super.key, this.proveedor});

  @override
  ConsumerState<ProveedorFormSheet> createState() => _ProveedorFormSheetState();
}

class _ProveedorFormSheetState extends ConsumerState<ProveedorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _contactoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _notasCtrl;

  String? _tipo;
  int? _rating;

  bool get _isEditing => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _contactoCtrl = TextEditingController(text: p?.contacto ?? '');
    _telefonoCtrl = TextEditingController(text: p?.telefono ?? '');
    _notasCtrl = TextEditingController(text: p?.notas ?? '');
    _tipo = p?.tipo;
    _rating = p?.rating;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _contactoCtrl.dispose();
    _telefonoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(gestionarProveedorProvider.notifier);
    final ok = _isEditing
        ? await notifier.actualizar(
            id: widget.proveedor!.id,
            nombre: _nombreCtrl.text,
            contacto: _contactoCtrl.text,
            telefono: _telefonoCtrl.text,
            tipo: _tipo,
            rating: _rating,
            notas: _notasCtrl.text,
          )
        : await notifier.crear(
            nombre: _nombreCtrl.text,
            contacto: _contactoCtrl.text,
            telefono: _telefonoCtrl.text,
            tipo: _tipo,
            rating: _rating,
            notas: _notasCtrl.text,
          );

    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        content: Text(
          _isEditing ? 'Proveedor actualizado' : 'Proveedor creado',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          'Error al guardar — revisa los datos',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestionarProveedorProvider);
    final isLoading = state is AsyncLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Editar proveedor' : 'Nuevo proveedor',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Nombre*'),
                _AppFormField(
                  controller: _nombreCtrl,
                  hint: 'Ej: Textiles San Miguel',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Tipo'),
                _TipoSelector(
                  value: _tipo,
                  onChanged: (v) => setState(() => _tipo = v),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Contacto'),
                _AppFormField(
                  controller: _contactoCtrl,
                  hint: 'Nombre de la persona de contacto',
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Teléfono'),
                _AppFormField(
                  controller: _telefonoCtrl,
                  hint: '+51 999 999 999',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                RatingSelector(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Notas'),
                _AppFormField(
                  controller: _notasCtrl,
                  hint: 'Observaciones, condiciones de pago, etc.',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Guardar cambios' : 'Crear proveedor',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _AppFormField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      ),
    );
  }
}

class _TipoSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _TipoSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Proveedor.tiposDisponibles.map((entry) {
        final (val, label) = entry;
        final isActive = value == val;
        return GestureDetector(
          onTap: () => onChanged(isActive ? null : val),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
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
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

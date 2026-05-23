import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/briefs_provider.dart';
import 'color_chip.dart';

const int _maxImagenes = 8;
const int _maxColores = 8;

// --- Controller ---------------------------------------------------------------

class BriefFormController {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final tipografiaCtrl = TextEditingController();
  final notasCtrl = TextEditingController();

  String? dropId;
  bool dropSeleccionado = false; // true si eligió drop o "Prenda suelta"
  DateTime? fechaLimite;
  final List<String> colores = [];
  final List<({Uint8List bytes, String ext})> imagenes = [];

  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    tipografiaCtrl.dispose();
    notasCtrl.dispose();
  }

  bool get isValid =>
      tituloCtrl.text.trim().isNotEmpty &&
      dropSeleccionado &&
      descripcionCtrl.text.trim().isNotEmpty &&
      fechaLimite != null;
}

// --- Formulario ---------------------------------------------------------------

class BriefForm extends ConsumerStatefulWidget {
  final BriefFormController controller;
  final VoidCallback onChanged;

  const BriefForm({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  ConsumerState<BriefForm> createState() => _BriefFormState();
}

class _BriefFormState extends ConsumerState<BriefForm> {
  BriefFormController get _ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final dropsAsync = ref.watch(dropsDisponiblesProvider);
    final today = DateTime.now();
    final todayStr = '${today.day}/${today.month}/${today.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fecha de idea (automática, solo info)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                'Idea creada el $todayStr',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Título
        const _Label('TÍTULO DEL DISEÑO *'),
        const SizedBox(height: 8),
        _TextField(
          controller: _ctrl.tituloCtrl,
          hintText: 'Ej: Hoodie Volcán...',
          onChanged: (_) => widget.onChanged(),
        ),
        const SizedBox(height: 20),

        // 2. Drop asociado (con opción "Prenda suelta")
        const _Label('DROP ASOCIADO *'),
        const SizedBox(height: 8),
        dropsAsync.when(
          loading: () => const SizedBox(
              height: 36,
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent))),
          error: (_, __) => Text('Error cargando drops',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
          data: (drops) {
            final all = <Map<String, String?>>[
              {'id': null, 'nombre': 'Prenda suelta'},
              ...drops.map((d) => {'id': d['id'], 'nombre': d['nombre']}),
            ];
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: all.map((d) {
                  final isSelected = d['id'] == null
                      ? (_ctrl.dropSeleccionado && _ctrl.dropId == null)
                      : _ctrl.dropId == d['id'];
                  final isPrendaSuelta = d['id'] == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _ctrl.dropId = d['id'];
                          _ctrl.dropSeleccionado = true;
                        });
                        widget.onChanged();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPrendaSuelta)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.label_off_outlined,
                                    size: 13,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textTertiary),
                              ),
                            Text(
                              d['nombre']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // 3. Descripción
        const _Label('DESCRIPCIÓN *'),
        const SizedBox(height: 8),
        _TextField(
          controller: _ctrl.descripcionCtrl,
          hintText: 'Describe el concepto del diseño...',
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => widget.onChanged(),
        ),
        const SizedBox(height: 20),

        // 4. Colores de referencia · sistema mixto
        const _Label('COLORES DE REFERENCIA (máx $_maxColores)'),
        const SizedBox(height: 8),
        ColorPaletteSelector(
          seleccionados: _ctrl.colores,
          maxColores: _maxColores,
          onAdd: (nombre) {
            if (!_ctrl.colores.contains(nombre) &&
                _ctrl.colores.length < _maxColores) {
              setState(() => _ctrl.colores.add(nombre));
              widget.onChanged();
            }
          },
          onRemove: (nombre) {
            setState(() => _ctrl.colores.remove(nombre));
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),

        // 5. Imágenes de referencia
        const _Label('IMÁGENES DE REFERENCIA (opcional, máx $_maxImagenes)'),
        const SizedBox(height: 4),
        Text(
          '${_ctrl.imagenes.length}/$_maxImagenes',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        _ReferenciaImagenGrid(
          imagenes: _ctrl.imagenes,
          onAdd: _pickImagen,
          onRemove: (i) {
            setState(() => _ctrl.imagenes.removeAt(i));
            widget.onChanged();
          },
        ),
        const SizedBox(height: 20),

        // 6. Tipografía sugerida
        const _Label('TIPOGRAFÍA SUGERIDA'),
        const SizedBox(height: 8),
        _TextField(
          controller: _ctrl.tipografiaCtrl,
          hintText: 'Ej: Space Grotesk Bold...',
          onChanged: (_) => widget.onChanged(),
        ),
        const SizedBox(height: 20),

        // 7. Fecha límite de entrega
        const _Label('¿CUÁNDO NECESITAS EL DISEÑO TERMINADO? *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _ctrl.fechaLimite != null
                    ? AppColors.accent
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: _ctrl.fechaLimite != null
                        ? AppColors.accent
                        : AppColors.textTertiary),
                const SizedBox(width: 10),
                Text(
                  _ctrl.fechaLimite != null
                      ? _formatFecha(_ctrl.fechaLimite!)
                      : 'Seleccionar fecha de entrega...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _ctrl.fechaLimite != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 8. Notas adicionales
        const _Label('NOTAS ADICIONALES'),
        const SizedBox(height: 8),
        _TextField(
          controller: _ctrl.notasCtrl,
          hintText: 'Cualquier detalle extra para la diseñadora...',
          maxLines: 3,
          onChanged: (_) => widget.onChanged(),
        ),
      ],
    );
  }

  Future<void> _pickImagen() async {
    if (_ctrl.imagenes.length >= _maxImagenes) return;
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      setState(() => _ctrl.imagenes.add((bytes: bytes, ext: ext)));
      widget.onChanged();
    } catch (e) {
      if (kDebugMode) print('[pick imagen ref] ERROR: $e');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _ctrl.fechaLimite = picked);
      widget.onChanged();
    }
  }

  String _formatFecha(DateTime d) {
    const meses = [
      'enero','febrero','marzo','abril','mayo','junio',
      'julio','agosto','septiembre','octubre','noviembre','diciembre',
    ];
    return '${d.day} de ${meses[d.month - 1]} ${d.year}';
  }
}

// --- Grid de imágenes de referencia ------------------------------------------

class _ReferenciaImagenGrid extends StatelessWidget {
  final List<({Uint8List bytes, String ext})> imagenes;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ReferenciaImagenGrid({
    required this.imagenes,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      ...imagenes.asMap().entries.map((e) => _ThumbItem(
            bytes: e.value.bytes,
            onRemove: () => onRemove(e.key),
          )),
      if (imagenes.length < _maxImagenes) _AddButton(onTap: onAdd),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }
}

class _ThumbItem extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;
  const _ThumbItem({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 22, color: AppColors.textTertiary),
            const SizedBox(height: 4),
            Text('SUBIR',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// --- Widgets internos ---------------------------------------------------------

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
          letterSpacing: 0.8),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _TextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface2,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        counterStyle:
            GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
      ),
    );
  }
}

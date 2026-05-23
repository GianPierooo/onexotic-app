import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/calendario_provider.dart';

const _tipos = [
  'Reunión de equipo',
  'Lanzamiento de drop',
  'Fecha límite de diseño',
  'Fecha límite de tarea',
  'Evento especial',
];

const _colores = [
  ('#FF4500', 'Naranja · Drop'),
  ('#3B82F6', 'Azul · Reunión'),
  ('#F59E0B', 'Amarillo · Tarea'),
  ('#22C55E', 'Verde · Diseño'),
  ('#A78BFA', 'Púrpura · Especial'),
];

class NuevoEventoSheet extends ConsumerStatefulWidget {
  final DateTime? fechaInicial;
  final EventoCalendario? eventoEditar;

  const NuevoEventoSheet({super.key, this.fechaInicial, this.eventoEditar});

  @override
  ConsumerState<NuevoEventoSheet> createState() => _NuevoEventoSheetState();
}

class _NuevoEventoSheetState extends ConsumerState<NuevoEventoSheet> {
  late String _tipo;
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _lugarCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _fecha;
  TimeOfDay? _hora;
  late String _colorHex;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final e = widget.eventoEditar;
    _tipo = e != null ? (e.tipoDb ?? _tipos.first) : _tipos.first;
    _tituloCtrl = TextEditingController(text: e?.titulo ?? '');
    _lugarCtrl = TextEditingController(text: e?.lugar ?? '');
    _descCtrl = TextEditingController(text: e?.descripcion ?? '');
    _fecha = e?.fecha ?? widget.fechaInicial ?? DateTime.now();
    _hora = e?.hora;
    _colorHex = e?.colorHex ?? '#FF4500';
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _lugarCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _tituloCtrl.text.trim().isNotEmpty;

  Future<void> _guardar() async {
    if (!_isValid) return;
    setState(() => _errorMsg = null);

    final esEditar = widget.eventoEditar != null;
    bool ok;
    if (esEditar) {
      ok = await ref.read(editarEventoProvider.notifier).editar(
            eventoId: widget.eventoEditar!.id,
            tipo: _tipo,
            titulo: _tituloCtrl.text.trim(),
            fecha: _fecha,
            hora: _hora,
            lugar: _lugarCtrl.text,
            descripcion: _descCtrl.text,
            colorHex: _colorHex,
          );
    } else {
      ok = await ref.read(crearEventoProvider.notifier).crear(
            tipo: _tipo,
            titulo: _tituloCtrl.text.trim(),
            fecha: _fecha,
            hora: _hora,
            lugar: _lugarCtrl.text,
            descripcion: _descCtrl.text,
            colorHex: _colorHex,
          );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // Muestra el error al usuario · no silencioso
      final rawErr = esEditar
          ? ref.read(editarEventoProvider).error
          : ref.read(crearEventoProvider).error;
      setState(() {
        _errorMsg = _mensajeError(rawErr);
      });
    }
  }

  String _mensajeError(Object? err) {
    if (err == null) return 'No se pudo guardar el evento.';
    final msg = err.toString().toLowerCase();
    if (msg.contains('security policy') || msg.contains('42501')) {
      return 'Sin permisos para crear eventos. Verifica las políticas RLS en Supabase.';
    }
    if (msg.contains('does not exist') || msg.contains('42p01')) {
      return 'La tabla eventos_calendario no existe. Ejecuta el SQL en el dashboard de Supabase.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Sin conexión. Verifica tu red e intenta de nuevo.';
    }
    return 'Error al guardar: verifica la conexión e intenta de nuevo.';
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
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
    if (picked != null) setState(() => _hora = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventoEditar != null;
    final isLoading = ref.watch(crearEventoProvider) is AsyncLoading ||
        ref.watch(editarEventoProvider) is AsyncLoading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  isEditing ? 'Editar evento' : 'Nuevo evento',
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 20),

            // Tipo
            const _Label('TIPO DE EVENTO *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tipos.map((t) {
                final sel = _tipo == t;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tipo = t;
                      // Auto-color según tipo
                      _colorHex = switch (t) {
                        'Reunión de equipo'    => '#3B82F6',
                        'Lanzamiento de drop'  => '#FF4500',
                        'Fecha límite de diseño' => '#22C55E',
                        'Fecha límite de tarea'  => '#F59E0B',
                        _                       => '#A78BFA',
                      };
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? hexToColor(_colorHex).withValues(alpha: 0.15)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? hexToColor(_colorHex)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sel
                            ? hexToColor(_colorHex)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Título
            const _Label('TÍTULO *'),
            const SizedBox(height: 6),
            _Input(
              controller: _tituloCtrl,
              hint: 'Ej: Reunión de estrategia...',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Fecha y hora (row)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('FECHA *'),
                      const SizedBox(height: 6),
                      _PickerButton(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat("d MMM yyyy", 'es').format(_fecha),
                        active: true,
                        onTap: _pickFecha,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('HORA (opcional)'),
                      const SizedBox(height: 6),
                      _PickerButton(
                        icon: Icons.access_time_rounded,
                        label: _hora != null
                            ? '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}'
                            : 'Sin hora',
                        active: _hora != null,
                        onTap: _pickHora,
                        trailing: _hora != null
                            ? GestureDetector(
                                onTap: () => setState(() => _hora = null),
                                child: Icon(Icons.close_rounded,
                                    size: 14, color: AppColors.textTertiary),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lugar
            const _Label('LUGAR (opcional)'),
            const SizedBox(height: 6),
            _Input(
                controller: _lugarCtrl, hint: 'Ej: Showroom, Zoom...'),
            const SizedBox(height: 16),

            // Descripción
            const _Label('DESCRIPCIÓN (opcional)'),
            const SizedBox(height: 6),
            _Input(
              controller: _descCtrl,
              hint: 'Agrega más detalles...',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Color
            const _Label('COLOR DEL EVENTO'),
            const SizedBox(height: 10),
            Row(
              children: _colores.map(((String, String) c) {
                final sel = _colorHex == c.$1;
                final color = hexToColor(c.$1);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorHex = c.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: sel ? 36 : 28,
                      height: sel ? 36 : 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(
                                color: Colors.white, width: 3)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isValid && !isLoading) ? _guardar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEditing ? 'Guardar cambios' : 'Crear evento',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Mensaje de error visible cuando el guardado falla
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Widgets de soporte -------------------------------------------------------

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
          letterSpacing: 0.8));
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _Input(
      {required this.controller,
      required this.hint,
      this.maxLines = 1,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style:
          GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
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

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: active ? AppColors.accent : AppColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  )),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

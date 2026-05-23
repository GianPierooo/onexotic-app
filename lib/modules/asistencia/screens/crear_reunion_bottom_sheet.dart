import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/reuniones_provider.dart';

class CrearReunionBottomSheet extends ConsumerStatefulWidget {
  const CrearReunionBottomSheet({super.key});

  @override
  ConsumerState<CrearReunionBottomSheet> createState() =>
      _CrearReunionBottomSheetState();
}

class _CrearReunionBottomSheetState
    extends ConsumerState<CrearReunionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _lugarCtrl = TextEditingController(text: 'Showroom');
  final _descripcionCtrl = TextEditingController();
  final _temaCtrl = TextEditingController();

  String _tipo = 'diaria';
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);
  final List<String> _temas = [];
  List<Map<String, dynamic>> _todosUsuarios = [];
  Set<String> _selectedIds = {};
  bool _loadingUsuarios = true;

  // Recurrencia
  String _recurrencia = 'ninguna';
  DateTime? _recurrenciaFin;
  Set<int> _diasSemana = {}; // 1=Lun, 2=Mar, ... 7=Dom

  static const _tipos = [
    ('diaria', 'Reunión diaria'),
    ('semanal', 'Reunión semanal'),
    ('extraordinaria', 'Reunión extraordinaria'),
  ];

  static const _recurrencias = [
    ('ninguna',       'Sin repetición'),
    ('diaria',        'Todos los días'),
    ('semanal',       'Cada semana (mismo día)'),
    ('laboral',       'Lunes a viernes'),
    ('personalizado', 'Personalizado'),
  ];

  static const _nombresDia = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _lugarCtrl.dispose();
    _descripcionCtrl.dispose();
    _temaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('id, nombre, rol')
          .eq('activo', true)
          .order('nombre');
      setState(() {
        _todosUsuarios = (data as List).cast<Map<String, dynamic>>();
        _selectedIds = _todosUsuarios.map((u) => u['id'] as String).toSet();
        _loadingUsuarios = false;
      });
    } catch (e) {
      setState(() => _loadingUsuarios = false);
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
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
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _pickFechaFin() async {
    final defaultFin = _fecha.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenciaFin ?? defaultFin,
      firstDate: _fecha.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) setState(() => _recurrenciaFin = picked);
  }

  void _agregarTema() {
    final tema = _temaCtrl.text.trim();
    if (tema.isEmpty) return;
    setState(() {
      _temas.add(tema);
      _temaCtrl.clear();
    });
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIds.isEmpty) {
      _snack('Selecciona al menos un participante', isError: true);
      return;
    }
    final horaStr =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';
    final ok = await ref.read(crearReunionProvider.notifier).crear(
          tipo: _tipo,
          fecha: _fecha,
          hora: horaStr,
          lugar: _lugarCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          temas: _temas,
          participantesIds: _selectedIds.toList(),
          recurrencia: _recurrencia,
          recurrenciaFin: _recurrencia != 'ninguna' ? _recurrenciaFin : null,
          recurrenciaDias: _recurrencia == 'personalizado'
              ? _diasSemana.toList()
              : [],
        );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Reunión creada',
            style:
                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    } else {
      final err = ref.read(crearReunionProvider);
      _snack(
          err is AsyncError ? err.error.toString() : 'Error al crear reunión',
          isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(crearReunionProvider) is AsyncLoading;
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
                  child: Text('Nueva reunión',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
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
                    // Tipo
                    _label('Tipo de reunión *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      dropdownColor: AppColors.surface2,
                      iconEnabledColor: AppColors.textTertiary,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      items: _tipos
                          .map((t) => DropdownMenuItem(
                                value: t.$1,
                                child: Text(t.$2,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _tipo = v ?? 'diaria'),
                      decoration: _inputDeco('Tipo'),
                    ),
                    const SizedBox(height: 14),

                    // Fecha + Hora
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Fecha *'),
                              const SizedBox(height: 6),
                              _DateButton(
                                label:
                                    DateFormat('dd/MM/yyyy').format(_fecha),
                                icon: Icons.calendar_today_outlined,
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
                              _label('Hora *'),
                              const SizedBox(height: 6),
                              _DateButton(
                                label:
                                    '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                                icon: Icons.access_time_rounded,
                                onTap: _pickHora,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Lugar
                    _label('Lugar'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lugarCtrl,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: _inputDeco('Showroom'),
                    ),
                    const SizedBox(height: 14),

                    // Descripción
                    _label('Agenda / descripción'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration:
                          _inputDeco('¿Qué se va a tratar en la reunión?'),
                    ),
                    const SizedBox(height: 14),

                    // Temas
                    _label('Temas a tratar'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _temaCtrl,
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppColors.textPrimary),
                            decoration: _inputDeco('Agregar tema...'),
                            onFieldSubmitted: (_) => _agregarTema(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _agregarTema,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    if (_temas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _temas.asMap().entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.value,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _temas.removeAt(e.key)),
                                  child: Icon(Icons.close_rounded,
                                      size: 14,
                                      color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Participantes
                    _label('Participantes'),
                    const SizedBox(height: 6),
                    _loadingUsuarios
                        ? const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: _todosUsuarios.asMap().entries.map(
                                (entry) {
                                  final i = entry.key;
                                  final u = entry.value;
                                  final uid = u['id'] as String;
                                  final selected = _selectedIds.contains(uid);
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () => setState(() {
                                          if (selected) {
                                            _selectedIds.remove(uid);
                                          } else {
                                            _selectedIds.add(uid);
                                          }
                                        }),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 11),
                                          child: Row(
                                            children: [
                                              _Avatar(
                                                  nombre:
                                                      u['nombre'] as String),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(u['nombre'] as String,
                                                        style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: AppColors
                                                                .textPrimary)),
                                                    Text(
                                                        _labelRol(u['rol']
                                                            as String),
                                                        style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary)),
                                                  ],
                                                ),
                                              ),
                                              AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? AppColors.accent
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: selected
                                                        ? AppColors.accent
                                                        : AppColors.borderHover,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: selected
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        size: 14,
                                                        color: Colors.white)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (i < _todosUsuarios.length - 1)
                                        Divider(
                                            height: 1,
                                            color: AppColors.border,
                                            indent: 14,
                                            endIndent: 14),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                    const SizedBox(height: 14),

                    // ── Recurrencia ───────────────────────────────────
                    _label('Repetición'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _recurrencia,
                      dropdownColor: AppColors.surface2,
                      iconEnabledColor: AppColors.textTertiary,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      items: _recurrencias
                          .map((r) => DropdownMenuItem(
                                value: r.$1,
                                child: Text(r.$2,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _recurrencia = v ?? 'ninguna';
                        if (_recurrencia == 'ninguna') {
                          _recurrenciaFin = null;
                          _diasSemana = {};
                        }
                      }),
                      decoration: _inputDeco('Sin repetición'),
                    ),

                    // Días personalizados
                    if (_recurrencia == 'personalizado') ...[
                      const SizedBox(height: 10),
                      _label('Días de la semana'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: List.generate(7, (i) {
                          final dia = i + 1; // 1=Lun...7=Dom
                          final sel = _diasSemana.contains(dia);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) {
                                _diasSemana.remove(dia);
                              } else {
                                _diasSemana.add(dia);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.accent : AppColors.surface2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel ? AppColors.accent : AppColors.border,
                                ),
                              ),
                              child: Text(
                                _nombresDia[i],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],

                    // Fecha de fin de recurrencia
                    if (_recurrencia != 'ninguna') ...[
                      const SizedBox(height: 10),
                      _label('Fecha de fin (opcional · default 30 días)'),
                      const SizedBox(height: 6),
                      _DateButton(
                        label: _recurrenciaFin != null
                            ? DateFormat('dd/MM/yyyy').format(_recurrenciaFin!)
                            : DateFormat('dd/MM/yyyy')
                                .format(_fecha.add(const Duration(days: 30))),
                        icon: Icons.event_available_outlined,
                        onTap: _pickFechaFin,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón crear
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _crear,
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
                            : Text('Crear reunión',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
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

  String _labelRol(String r) => switch (r) {
        'ceo' => 'CEO',
        'disenadora' => 'Diseñadora',
        'rrhh' => 'RRHH',
        'produccion' => 'Producción',
        _ => r,
      };

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));

  InputDecoration _inputDeco(String hint) => InputDecoration(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

// ─── Helpers visuales ─────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nombre;
  const _Avatar({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.accentDim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_fab.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/tareas_provider.dart';
import '../widgets/area_badge.dart';
import '../widgets/filtro_pills.dart';
import '../widgets/prioridad_badge.dart';
import '../widgets/tarea_item.dart';

class TareasScreen extends ConsumerWidget {
  const TareasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareasAsync = ref.watch(tareasProvider);
    final userAsync = ref.watch(currentUserProvider);

    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? '',
      orElse: () => '',
    );
    final isAdmin = rol == 'ceo' || rol == 'manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isAdmin
          ? AppFab(onPressed: () => _showCreateModal(context, ref))
          : null,
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'tareas',
            slides: GuiasContent.tareas,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: tareasAsync.when(
                loading: () => _header(context, 'Cargando...', ''),
                error: (_, __) => _header(context, 'Tareas', ''),
                data: (tareas) {
                  final pendientes =
                      tareas.where((t) => !t.completado).length;
                  final urgentes = tareas
                      .where((t) => !t.completado && t.prioridad == 'alta')
                      .length;
                  return _header(
                    context,
                    '$pendientes pendientes',
                    urgentes > 0 ? '$urgentes urgentes' : '',
                  );
                },
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Filtros ────────────────────────────────────────────────
            const FiltroPills(),

            const SizedBox(height: 16),

            // ── Lista ──────────────────────────────────────────────────
            Expanded(
              child: tareasAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                error: (e, _) => _ErrorCard('$e'),
                data: (tareas) {
                  if (tareas.isEmpty) {
                    return _EmptyState(
                      filtro: ref.watch(tareasFiltroProvider),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface2,
                    onRefresh: () async => ref.invalidate(tareasProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: tareas.length,
                      itemBuilder: (context, i) {
                        final tarea = tareas[i];
                        return TareaItem(
                          key: ValueKey(tarea.id),
                          tarea: tarea,
                          onTap: () => context.push(
                            '/tareas/${tarea.id}',
                            extra: tarea,
                          ),
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

  Widget _header(BuildContext context, String line1, String line2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tareas',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (line1.isNotEmpty || line2.isNotEmpty)
                Text(
                  [line1, if (line2.isNotEmpty) line2].join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const GuiaHelpButton(slides: GuiasContent.tareas),
      ],
    );
  }

  void _showCreateModal(BuildContext context, WidgetRef ref) {
    // SIN addPostFrameCallback (problema conocido: no dispara si no hay
    // frame agendado). El tap mismo agenda el frame del showModalBottomSheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateTareaSheet(
        onCreated: () => ref.invalidate(tareasProvider),
      ),
    );
  }
}

// ─── Modal de creación ─────────────────────────────────────────────────────────

class _CreateTareaSheet extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  const _CreateTareaSheet({this.onCreated});

  @override
  ConsumerState<_CreateTareaSheet> createState() => _CreateTareaSheetState();
}

class _CreateTareaSheetState extends ConsumerState<_CreateTareaSheet> {
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _area = 'tech';
  String _prioridad = 'media';
  String? _asignadoA;
  DateTime? _fechaLimite;
  Uint8List? _imagenBytes;
  String _imagenExt = 'jpg';
  bool _uploadingImage = false;

  /// Error visible INLINE en el sheet (no SnackBar — el SnackBar queda atrás
  /// del bottom sheet y el usuario nunca lo ve).
  String? _errorMsg;

  static const _areas = [
    'tech', 'disenio', 'marketing', 'produccion', 'rrhh', 'legal',
  ];
  static const _prioridades = ['alta', 'media', 'baja'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.surface2,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaLimite = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _imagenBytes = bytes;
      _imagenExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'jpg';
    });
  }

  Future<void> _crear() async {
    debugPrint('[crear tarea] tap "Crear tarea" — iniciando submit');
    setState(() => _errorMsg = null);

    if (!_formKey.currentState!.validate()) {
      debugPrint('[crear tarea] validación de formulario falló');
      setState(() => _errorMsg = 'Completa los campos requeridos');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    String? imagenUrl;
    if (_imagenBytes != null) {
      debugPrint('[crear tarea] subiendo imagen (${_imagenBytes!.length} bytes)');
      setState(() => _uploadingImage = true);
      try {
        imagenUrl =
            await uploadImagenTarea(bytes: _imagenBytes!, ext: _imagenExt);
      } catch (e, st) {
        debugPrint('[crear tarea] EXCEPCIÓN subiendo imagen: $e');
        debugPrint('$st');
      }
      if (mounted) setState(() => _uploadingImage = false);
      if (imagenUrl == null) {
        debugPrint('[crear tarea] upload imagen devolvió null');
        setState(() => _errorMsg =
            'No se pudo subir la imagen. Intenta de nuevo o quítala.');
        return;
      }
      debugPrint('[crear tarea] imagen subida OK: $imagenUrl');
    }

    final descTrim = _descripcionCtrl.text.trim();
    debugPrint(
        '[crear tarea] enviando: titulo=${_tituloCtrl.text.trim()} '
        'area=$_area prioridad=$_prioridad '
        'asignado=$_asignadoA fecha=$_fechaLimite '
        'desc=${descTrim.isEmpty ? 'null' : '${descTrim.length} chars'} '
        'img=${imagenUrl != null}');

    try {
      final result = await ref.read(crearTareaProvider.notifier).crear(
            titulo: _tituloCtrl.text,
            area: _area,
            prioridad: _prioridad,
            asignadoA: _asignadoA,
            descripcion: descTrim.isEmpty ? null : descTrim,
            fechaLimite: _fechaLimite,
            imagenUrl: imagenUrl,
          );

      if (!mounted) return;
      if (result.ok) {
        debugPrint('[crear tarea] OK — cerrando sheet');
        widget.onCreated?.call();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success.withValues(alpha: 0.95),
            content: Text(
              'Tarea creada',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ),
        );
      } else {
        debugPrint('[crear tarea] FALLÓ: ${result.error}');
        setState(() => _errorMsg = result.error ?? 'No se pudo crear la tarea');
      }
    } catch (e, st) {
      // Cinturón y tirantes: aunque el provider ya captura PostgrestException
      // y errores genéricos, si algo raro escapa lo mostramos igual.
      debugPrint('[crear tarea] EXCEPCIÓN NO CAPTURADA: $e');
      debugPrint('$st');
      if (mounted) setState(() => _errorMsg = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final crearState = ref.watch(crearTareaProvider);
    final isLoading = crearState is AsyncLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      constraints: BoxConstraints(
        // Limita a 90% del alto disponible para que el contenido siempre
        // tenga espacio al botón "Crear tarea" aunque el teclado esté abierto.
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Text(
              'Nueva tarea',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Banner de error visible — el SnackBar queda detrás del sheet
            // (mismo eje vertical inferior), así que mostramos el error aquí
            // adentro del modal para que el usuario lo vea sí o sí.
            if (_errorMsg != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.error,
                          height: 1.35,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMsg = null),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // Título
            TextFormField(
              controller: _tituloCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Título de la tarea...',
                hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12,
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 16),

            // Área
            const _SheetLabel('ÁREA'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _areas
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _area = a),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _area == a
                                    ? AreaBadge.colorForArea(a)
                                    : AppColors.surface2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _area == a
                                      ? AreaBadge.colorForArea(a)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                AreaBadge.labelForArea(a),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _area == a
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Prioridad
            const _SheetLabel('PRIORIDAD'),
            const SizedBox(height: 8),
            Row(
              children: _prioridades
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _prioridad = p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _prioridad == p
                                  ? PrioridadBadge.colorForPrioridad(p)
                                  : AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _prioridad == p
                                    ? PrioridadBadge.colorForPrioridad(p)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              PrioridadBadge.labelForPrioridad(p),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _prioridad == p
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Asignar a
            const _SheetLabel('ASIGNAR A (opcional)'),
            const SizedBox(height: 8),
            ref.watch(usuariosActivosProvider).when(
              loading: () => const SizedBox(height: 44),
              error: (_, __) => const SizedBox.shrink(),
              data: (usuarios) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _asignadoA,
                    hint: Text(
                      'Sin asignar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    dropdownColor: AppColors.surface2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Sin asignar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      ...usuarios.map((u) => DropdownMenuItem<String?>(
                            value: u.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      u.iniciales,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    u.nombre,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface3,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.rolLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (val) => setState(() => _asignadoA = val),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descripción
            const _SheetLabel('DESCRIPCIÓN (opcional)'),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _descripcionCtrl,
              builder: (_, __, ___) {
                final len = _descripcionCtrl.text.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      maxLength: 300,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Descripción de la tarea...',
                        hintStyle:
                            GoogleFonts.inter(color: AppColors.textTertiary),
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$len/300',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: len > 280
                            ? AppColors.warning
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Fecha límite
            const _SheetLabel('FECHA LÍMITE (opcional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fechaLimite == null
                            ? 'Sin fecha'
                            : '${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _fechaLimite == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_fechaLimite != null)
                      GestureDetector(
                        onTap: () => setState(() => _fechaLimite = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textTertiary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Imagen adjunta
            const _SheetLabel('IMAGEN ADJUNTA (opcional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: _imagenBytes != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _imagenBytes!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imagenBytes = null),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.background.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 24, color: AppColors.textTertiary),
                          const SizedBox(height: 4),
                          Text(
                            'Seleccionar imagen',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Botón crear
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isLoading || _uploadingImage) ? null : _crear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: (isLoading || _uploadingImage)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Crear tarea',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Widgets de soporte ────────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Error al cargar tareas',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(tareasProvider),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label:
                  Text('Reintentar', style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TareasFiltro filtro;
  const _EmptyState({required this.filtro});

  @override
  Widget build(BuildContext context) {
    final msg = filtro.estado == 'completadas'
        ? 'No hay tareas completadas'
        : filtro.area != null
            ? 'No hay tareas en esta área'
            : 'No hay tareas pendientes';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

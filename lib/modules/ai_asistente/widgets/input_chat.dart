
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/voice/speech_service.dart';

class InputChat extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final void Function(String) onSend;
  final String? hint;

  /// Si está presente, se muestra el botón de adjuntar imágenes y al enviar
  /// se llama con el texto + los bytes de las imágenes seleccionadas.
  /// Cuando es null, el botón no se muestra (modo chat informativo).
  final void Function(String texto, List<PickedImage> imagenes)? onSendConImagenes;

  /// Si es true, muestra el botón de dictado por voz junto a adjuntar.
  /// Solo se usa en el modo Asistente — el modo Chat queda intacto.
  final bool enableVoice;

  /// Si es true, deshabilita acciones (subiendo imágenes en background).
  final bool isSubiendo;

  const InputChat({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    this.hint,
    this.onSendConImagenes,
    this.enableVoice = false,
    this.isSubiendo = false,
  });

  @override
  State<InputChat> createState() => _InputChatState();
}

class _InputChatState extends State<InputChat> {
  bool _hasText = false;
  bool _focused = false;
  final List<PickedImage> _adjuntas = [];

  // ─── Estado del dictado por voz ────────────────────────────────────────────
  // _textoPrevio: lo que había en el campo antes de empezar a dictar. Se usa
  // para preservar lo que el CEO ya había tecleado y solo concatenar lo nuevo.
  final SpeechService _voice = SpeechService();
  bool _escuchando = false;
  String _textoPrevio = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateHasText);
    widget.focusNode.addListener(_updateFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasText);
    widget.focusNode.removeListener(_updateFocus);
    // No await: dispose es sync. cancel() es defensivo por si el usuario
    // cerró la pantalla mientras dictaba.
    if (_escuchando) {
      _voice.cancel();
    }
    super.dispose();
  }

  void _updateHasText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _updateFocus() {
    if (widget.focusNode.hasFocus != _focused) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  Future<void> _adjuntarImagenes() async {
    try {
      final picker = ImagePicker();
      // Redimensiona en el dispositivo antes de leer bytes. Una foto de iPhone
      // sin esto son ~4000×3000 px / 4MB → al decodificarla para preview y
      // upload satura la GPU de Flutter web (CONTEXT_LOST_WEBGL).
      final result = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (result.isEmpty) return;
      // Tope defensivo: con > 5 imágenes en el chat la decodificación
      // simultánea para la galería es muy pesada.
      const maxAdjuntas = 5;
      final espacio = maxAdjuntas - _adjuntas.length;
      if (espacio <= 0) return;
      final aTomar = result.length > espacio ? result.sublist(0, espacio) : result;

      final picked = <PickedImage>[];
      for (final x in aTomar) {
        final bytes = await x.readAsBytes();
        final ext = (x.name.split('.').lastOrNull ?? 'jpg').toLowerCase();
        picked.add(PickedImage(
          bytes: bytes,
          ext: ext == 'jpeg' ? 'jpg' : ext,
          nombre: x.name,
        ));
      }
      if (!mounted) return;
      setState(() => _adjuntas.addAll(picked));
    } catch (_) {/* el usuario canceló o el picker falló */}
  }

  void _quitarAdjunta(int i) {
    setState(() => _adjuntas.removeAt(i));
  }

  // ─── Voz ─────────────────────────────────────────────────────────────────
  Future<void> _toggleVoz() async {
    if (_escuchando) {
      await _voice.stop();
      // El status callback nos pondrá _escuchando=false; igual lo forzamos
      // por si acaso (idempotente).
      if (mounted) setState(() => _escuchando = false);
      return;
    }
    HapticFeedback.selectionClick();
    final ok = await _voice.ensureInitialized(
      onStatus: (s) {
        // Estados de speech_to_text: 'listening', 'notListening', 'done'.
        // Solo nos importa salir de modo escuchando.
        if (!mounted) return;
        if (s == 'notListening' || s == 'done') {
          if (_escuchando) setState(() => _escuchando = false);
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _escuchando = false);
        _mostrarErrorVoz(e);
      },
    );
    if (!ok) return;
    _textoPrevio = widget.controller.text;
    final started = await _voice.listen(
      onPartial: (parcial) {
        if (!mounted) return;
        widget.controller.value = TextEditingValue(
          text: _componerTexto(parcial),
          selection: TextSelection.collapsed(
            offset: _componerTexto(parcial).length,
          ),
        );
      },
      onFinal: (texto) {
        if (!mounted) return;
        final compuesto = _componerTexto(texto);
        widget.controller.value = TextEditingValue(
          text: compuesto,
          selection: TextSelection.collapsed(offset: compuesto.length),
        );
        setState(() => _escuchando = false);
      },
    );
    if (started && mounted) {
      setState(() => _escuchando = true);
    }
  }

  String _componerTexto(String nuevo) {
    if (_textoPrevio.isEmpty) return nuevo;
    final sep = _textoPrevio.endsWith(' ') ? '' : ' ';
    return '$_textoPrevio$sep$nuevo';
  }

  void _mostrarErrorVoz(VoiceError e) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        duration: const Duration(seconds: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        content: Row(
          children: [
            Icon(
              e.tipo == VoiceErrorTipo.noEntendido
                  ? Icons.hearing_disabled_rounded
                  : Icons.mic_off_rounded,
              color: AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                e.mensaje,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSend =>
      !widget.isLoading &&
      !widget.isSubiendo &&
      !_escuchando &&
      (_hasText || _adjuntas.isNotEmpty);

  void _enviar() {
    if (!_canSend) return;
    HapticFeedback.selectionClick();
    final texto = widget.controller.text;
    if (_adjuntas.isNotEmpty && widget.onSendConImagenes != null) {
      widget.onSendConImagenes!(texto, List.of(_adjuntas));
      _adjuntas.clear();
    } else {
      widget.onSend(texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeAdjuntar = widget.onSendConImagenes != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).padding.bottom * 0.3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_adjuntas.isNotEmpty) _previewAdjuntas(),
          if (_escuchando) _bannerEscuchando(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (puedeAdjuntar) ...[
                _botonAdjuntar(),
                const SizedBox(width: 8),
              ],
              if (widget.enableVoice) ...[
                _botonVoz(),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  constraints: const BoxConstraints(maxHeight: 132),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    border: Border.all(
                      color: _focused ? AppColors.accent : AppColors.border,
                      width: _focused ? 1 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: !widget.isLoading && !widget.isSubiendo,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    maxLines: null,
                    cursorColor: AppColors.accent,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isSubiendo
                          ? 'Subiendo imágenes...'
                          : _escuchando
                              ? 'Escuchando…'
                              : (widget.hint ?? 'Pregunta algo...'),
                      hintStyle: GoogleFonts.inter(
                        color: _escuchando
                            ? AppColors.accent
                            : AppColors.textPlaceholder,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _botonEnviar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAdjuntar() {
    final disabled = widget.isLoading || widget.isSubiendo || _escuchando;
    return GestureDetector(
      onTap: disabled ? null : _adjuntarImagenes,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 20,
          color:
              disabled ? AppColors.textPlaceholder : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _botonVoz() {
    final disabled = widget.isLoading || widget.isSubiendo;
    final activo = _escuchando;
    final boton = GestureDetector(
      onTap: disabled ? null : _toggleVoz,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: activo
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surface2,
          border: Border.all(
            color: activo ? AppColors.accent : AppColors.border,
            width: activo ? 1.2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          activo ? Icons.stop_rounded : Icons.mic_none_rounded,
          size: 20,
          color: disabled
              ? AppColors.textPlaceholder
              : activo
                  ? AppColors.accent
                  : AppColors.textSecondary,
        ),
      ),
    );
    if (!activo) return boton;
    // Pulsación suave del fondo cuando está escuchando — sin partículas ni
    // efectos pesados para no provocar CONTEXT_LOST_WEBGL en flutter web.
    return boton
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 250.ms)
        .scaleXY(begin: 1, end: 1.06, duration: 700.ms, curve: Curves.easeInOut);
  }

  Widget _bannerEscuchando() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms)
              .then()
              .fade(begin: 1, end: 0.25, duration: 600.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Escuchando… habla con naturalidad',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleVoz,
            child: Text(
              'Detener',
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonEnviar() {
    return GestureDetector(
      onTap: _canSend ? _enviar : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: (widget.isLoading || widget.isSubiendo)
              ? AppColors.surface3
              : _canSend
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _canSend
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: (widget.isLoading || widget.isSubiendo)
            ? Padding(
                padding: const EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            : const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  Widget _previewAdjuntas() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _adjuntas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final img = _adjuntas[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.surface2,
                  child: Image.memory(
                    img.bytes,
                    fit: BoxFit.cover,
                    // cacheWidth limita el tamaño decodificado en GPU.
                    // 152 = 76 * 2 (densidad retina) — suficiente y barato.
                    cacheWidth: 152,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _quitarAdjunta(i),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Imagen seleccionada por el picker, lista para ser subida.
class PickedImage {
  final Uint8List bytes;
  final String ext;
  final String nombre;
  const PickedImage({
    required this.bytes,
    required this.ext,
    required this.nombre,
  });
}

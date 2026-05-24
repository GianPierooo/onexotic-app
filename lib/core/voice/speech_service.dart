// Wrapper sobre speech_to_text que:
//   • Normaliza el ciclo init → listen → stop.
//   • Traduce errores nativos a mensajes legibles en español.
//   • Reusa la misma instancia: speech_to_text NO permite múltiples instancias
//     simultáneas y reinicializarla en cada uso causa "audio_busy" en Android.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceErrorTipo {
  permisoDenegado,
  noDisponible,
  redOffline,
  audioOcupado,
  noEntendido,
  desconocido,
}

class VoiceError {
  final VoiceErrorTipo tipo;
  final String mensaje;
  const VoiceError(this.tipo, this.mensaje);
}

class SpeechService {
  static final SpeechService _i = SpeechService._();
  factory SpeechService() => _i;
  SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _available;

  /// Idempotente: si ya se inicializó, devuelve el último resultado.
  /// Devuelve true si el motor está disponible y los permisos fueron
  /// concedidos.
  Future<bool> ensureInitialized({
    required void Function(VoiceError err) onError,
    required void Function(String status) onStatus,
  }) async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onError: (e) {
          if (kDebugMode) print('[voice] error nativo: ${e.errorMsg}');
          onError(_mapearError(e.errorMsg));
        },
        onStatus: (s) {
          if (kDebugMode) print('[voice] status: $s');
          onStatus(s);
        },
        debugLogging: false,
      );
      _initialized = true;
      return _available;
    } catch (e) {
      if (kDebugMode) print('[voice] init exception: $e');
      _initialized = true;
      _available = false;
      onError(VoiceError(
        VoiceErrorTipo.noDisponible,
        'No se pudo iniciar el reconocimiento de voz. Probablemente el navegador no lo soporta o estás abriendo la app desde un webview. (detalle: $e)',
      ));
      return false;
    }
  }

  /// Empieza a escuchar. `onPartial` se llama con cada transcripción parcial,
  /// `onFinal` solo una vez con el texto definitivo (o cadena vacía si no
  /// reconoció nada).
  Future<bool> listen({
    required void Function(String parcial) onPartial,
    required void Function(String texto) onFinal,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 3),
    String localeId = 'es_ES',
  }) async {
    if (!_available) return false;
    if (_speech.isListening) return true;
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onFinal(result.recognizedWords);
          } else {
            onPartial(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
        ),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('[voice] listen exception: $e');
      return false;
    }
  }

  /// Detiene la escucha conservando lo ya reconocido (dispara onFinal).
  Future<void> stop() async {
    if (!_speech.isListening) return;
    try {
      await _speech.stop();
    } catch (e) {
      if (kDebugMode) print('[voice] stop exception: $e');
    }
  }

  /// Cancela la escucha descartando lo capturado.
  Future<void> cancel() async {
    if (!_speech.isListening) return;
    try {
      await _speech.cancel();
    } catch (e) {
      if (kDebugMode) print('[voice] cancel exception: $e');
    }
  }

  VoiceError _mapearError(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('permission') || s.contains('denied')) {
      return const VoiceError(
        VoiceErrorTipo.permisoDenegado,
        'Necesitas dar permiso al micrófono para dictar. Actívalo en los ajustes del navegador o del dispositivo.',
      );
    }
    if (s.contains('network')) {
      return const VoiceError(
        VoiceErrorTipo.redOffline,
        'Sin conexión. El reconocimiento de voz necesita internet.',
      );
    }
    if (s.contains('busy') || s.contains('audio_record')) {
      return const VoiceError(
        VoiceErrorTipo.audioOcupado,
        'El micrófono está ocupado por otra app. Ciérrala y vuelve a intentar.',
      );
    }
    if (s.contains('no_match') || s.contains('no match') || s.contains('no_speech') || s.contains('no-speech')) {
      return const VoiceError(
        VoiceErrorTipo.noEntendido,
        'No te entendí. Intenta hablar más cerca del micrófono.',
      );
    }
    // 'not supported' / 'speech_not_supported' / 'not_available' — todos
    // significan que el navegador no tiene Web Speech API o el dispositivo
    // no expone reconocimiento nativo. Incluimos el detalle crudo para
    // distinguir webview de navegador real al diagnosticar.
    if (s.contains('not supported') ||
        s.contains('not_supported') ||
        s.contains('speech_not_supported') ||
        s.contains('not_available') ||
        s.contains('not available')) {
      return VoiceError(
        VoiceErrorTipo.noDisponible,
        'Este navegador no soporta dictado por voz. Abre la app desde Chrome (Android), Safari (iOS 14.5+) o Edge — NO desde el navegador interno de Instagram, WhatsApp u otra app. (detalle: $raw)',
      );
    }
    return VoiceError(VoiceErrorTipo.desconocido, raw.isEmpty ? 'Error desconocido' : raw);
  }
}

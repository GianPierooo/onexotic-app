import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Modelo de mensaje ─────────────────────────────────────────────────────────

class MensajeChat {
  final String id;
  final String texto;
  final bool esUsuario;
  final DateTime timestamp;

  const MensajeChat({
    required this.id,
    required this.texto,
    required this.esUsuario,
    required this.timestamp,
  });
}

// ─── Estado del chat ───────────────────────────────────────────────────────────

class AiChatState {
  final List<MensajeChat> mensajes;
  final bool isTyping;
  final String? error;

  const AiChatState({
    this.mensajes = const [],
    this.isTyping = false,
    this.error,
  });

  AiChatState copyWith({
    List<MensajeChat>? mensajes,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      mensajes: mensajes ?? this.mensajes,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier() : super(const AiChatState());

  Future<void> enviar(String texto) async {
    if (texto.trim().isEmpty) return;

    // Captura historial ANTES de añadir el nuevo mensaje
    final historialPrev = state.mensajes.length > 6
        ? state.mensajes.sublist(state.mensajes.length - 6)
        : List<MensajeChat>.from(state.mensajes);

    final historial = historialPrev
        .map((m) => {
              'role': m.esUsuario ? 'user' : 'assistant',
              'content': m.texto,
            })
        .toList();

    final mensajeUsuario = MensajeChat(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      texto: texto.trim(),
      esUsuario: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, mensajeUsuario],
      isTyping: true,
      clearError: true,
    );

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {
          'mensaje': texto.trim(),
          'historial': historial,
        },
      );

      final respuesta = response.data['respuesta'] as String? ??
          'No tengo esa información disponible.';

      final mensajeAI = MensajeChat(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        texto: respuesta,
        esUsuario: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        mensajes: [...state.mensajes, mensajeAI],
        isTyping: false,
      );
    } catch (e) {
      if (kDebugMode) print('[ai-chat] ERROR: $e');
      state = state.copyWith(
        isTyping: false,
        error: 'No se pudo conectar con el asistente.',
      );
    }
  }

  void limpiar() {
    state = const AiChatState();
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(),
);

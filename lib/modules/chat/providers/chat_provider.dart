import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';
import '../models/mensaje_chat.dart';

// ─── Stream de mensajes entre el usuario actual y `otroUserId` ────────────────
//
// Usa Supabase Realtime para escuchar inserts/updates. La RLS de Postgres
// garantiza que solo recibimos filas donde participa el usuario actual.
// Filtramos en cliente por la conversación con `otroUserId`.

final mensajesChatProvider = StreamProvider.family
    .autoDispose<List<MensajeChat>, String>((ref, otroUserId) {
  final client = Supabase.instance.client;
  final yo = client.auth.currentUser?.id;
  if (yo == null) {
    return const Stream<List<MensajeChat>>.empty();
  }

  return client
      .from('mensajes_chat')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) {
        final mensajes = rows
            .map(MensajeChat.fromJson)
            .where((m) =>
                (m.deUserId == yo && m.paraUserId == otroUserId) ||
                (m.deUserId == otroUserId && m.paraUserId == yo))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return mensajes;
      });
});

// ─── Conteo de no leídos por usuario remitente ──────────────────────────────
// Devuelve un Map<senderId, count> donde el destinatario es el usuario actual.

final unreadCountsByUserProvider =
    StreamProvider.autoDispose<Map<String, int>>((ref) {
  final client = Supabase.instance.client;
  final yo = client.auth.currentUser?.id;
  if (yo == null) return const Stream<Map<String, int>>.empty();

  return client
      .from('mensajes_chat')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final counts = <String, int>{};
        for (final r in rows) {
          if (r['para_user_id'] == yo && (r['leido'] as bool? ?? false) == false) {
            final from = r['de_user_id'] as String;
            counts[from] = (counts[from] ?? 0) + 1;
          }
        }
        return counts;
      });
});

// ─── Total de mensajes no leídos para el usuario actual ─────────────────────

final totalUnreadProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(unreadCountsByUserProvider).maybeWhen(
        data: (m) => m.values.fold(0, (a, b) => a + b),
        orElse: () => 0,
      );
});

// ─── Enviar mensaje + push notification al destinatario ──────────────────────

class EnviarMensajeNotifier extends StateNotifier<AsyncValue<void>> {
  EnviarMensajeNotifier() : super(const AsyncValue.data(null));

  Future<bool> enviar({
    required String paraUserId,
    required String mensaje,
  }) async {
    final yo = Supabase.instance.client.auth.currentUser?.id;
    if (yo == null) return false;
    final texto = mensaje.trim();
    if (texto.isEmpty) return false;

    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('mensajes_chat').insert({
        'de_user_id': yo,
        'para_user_id': paraUserId,
        'mensaje': texto,
      });

      // Push fire-and-forget al destinatario. Lee el nombre del remitente
      // para componer el título "Nuevo mensaje de Gian Piero".
      _enviarPushAlDestinatario(yo, paraUserId, texto);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (kDebugMode) print('[chat] enviar ERROR: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _enviarPushAlDestinatario(
    String deUserId,
    String paraUserId,
    String texto,
  ) {
    () async {
      try {
        final remitente = await Supabase.instance.client
            .from('users')
            .select('nombre')
            .eq('id', deUserId)
            .maybeSingle();
        final nombre = remitente?['nombre'] as String? ?? 'Alguien';
        // pushNotif inserta en `notificaciones` (lo verá in-app via Realtime)
        // y dispara la Edge Function send-notification para push FCM.
        await pushNotif(
          userId: paraUserId,
          titulo: 'Nuevo mensaje de $nombre',
          mensaje: texto.length > 80 ? '${texto.substring(0, 80)}...' : texto,
          tipo: 'chat',
          referenciaId: deUserId,
        );
      } catch (e) {
        if (kDebugMode) print('[chat] push ERROR: $e');
      }
    }();
  }
}

final enviarMensajeProvider =
    StateNotifierProvider<EnviarMensajeNotifier, AsyncValue<void>>(
  (ref) => EnviarMensajeNotifier(),
);

// ─── Marcar mensajes como leídos al abrir la conversación ───────────────────

Future<void> marcarMensajesLeidos(String deUserId) async {
  final yo = Supabase.instance.client.auth.currentUser?.id;
  if (yo == null) return;
  try {
    await Supabase.instance.client
        .from('mensajes_chat')
        .update({'leido': true})
        .eq('de_user_id', deUserId)
        .eq('para_user_id', yo)
        .eq('leido', false);
  } catch (e) {
    if (kDebugMode) print('[chat] marcar leído ERROR: $e');
  }
}

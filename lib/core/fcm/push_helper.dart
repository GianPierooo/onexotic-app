// Centraliza el envío de push + insert en tabla notificaciones.
// Úsalo desde cualquier provider:
//   unawaited(pushNotif(userId: id, titulo: '...', mensaje: '...', tipo: 'tarea'));

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inserta en tabla `notificaciones` y llama a la Edge Function `send-notification`
/// de forma fire-and-forget (no bloquea si el push falla).
///
/// CRÍTICO: NO usar `.select()` en el INSERT — Postgres aplica la SELECT
/// policy a `RETURNING`. Como el destinatario (user_id) es DISTINTO al
/// auth.uid() del remitente, la visibility check rechaza el row y el INSERT
/// entero falla con `42501: row-level security`. Sin RETURNING el INSERT
/// pasa solo por WITH CHECK (auth.uid() IS NOT NULL) y se persiste.
Future<void> pushNotif({
  required String userId,
  required String titulo,
  required String mensaje,
  required String tipo,
  String? referenciaId,
}) async {
  final client = Supabase.instance.client;
  try {
    // 1. Persistir la notificación en BD (sin RETURNING).
    await client.from('notificaciones').insert({
      'user_id': userId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'leido': false,
      if (referenciaId != null) 'referencia_id': referenciaId,
    });
    if (kDebugMode) print('[pushNotif] in-app OK → $userId ($tipo)');

    // 2. Push via Edge Function (fire-and-forget). Si el destinatario no
    // tiene fcm_token, la función devuelve {sent:false, reason:"sin_token"}
    // y el push se omite — la notificación in-app igual quedó persistida.
    client.functions
        .invoke(
          'send-notification',
          body: {
            'user_id': userId,
            'titulo': titulo,
            'mensaje': mensaje,
            'tipo': tipo,
          },
        )
        .then((res) {
          if (kDebugMode) print('[pushNotif] FCM resp: ${res.data}');
        })
        .catchError((e) {
          if (kDebugMode) print('[pushNotif] FCM ERROR: $e');
        });
  } catch (e) {
    if (kDebugMode) print('[pushNotif] ERROR: $e');
  }
}

/// Envía push a múltiples usuarios en paralelo.
Future<void> pushNotifMultiple({
  required List<String> userIds,
  required String titulo,
  required String mensaje,
  required String tipo,
  String? referenciaId,
}) async {
  await Future.wait(
    userIds.map(
      (id) => pushNotif(
        userId: id,
        titulo: titulo,
        mensaje: mensaje,
        tipo: tipo,
        referenciaId: referenciaId,
      ),
    ),
    eagerError: false,
  );
}

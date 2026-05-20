// Centraliza el envío de push + insert en tabla notificaciones.
// Úsalo desde cualquier provider:
//   unawaited(pushNotif(userId: id, titulo: '...', mensaje: '...', tipo: 'tarea'));

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inserta en tabla `notificaciones` y llama a la Edge Function `send-notification`
/// de forma fire-and-forget (no bloquea si el push falla).
Future<void> pushNotif({
  required String userId,
  required String titulo,
  required String mensaje,
  required String tipo,
  String? referenciaId,
}) async {
  final client = Supabase.instance.client;
  try {
    // 1. Persistir la notificación en BD
    final row = await client
        .from('notificaciones')
        .insert({
          'user_id': userId,
          'titulo': titulo,
          'mensaje': mensaje,
          'tipo': tipo,
          'leido': false,
          if (referenciaId != null) 'referencia_id': referenciaId,
        })
        .select('id')
        .maybeSingle();

    final notifId = row?['id'] as String?;

    // 2. Push via Edge Function (fire-and-forget)
    client.functions
        .invoke(
          'send-notification',
          body: {
            'user_id': userId,
            'titulo': titulo,
            'mensaje': mensaje,
            'tipo': tipo,
            if (notifId != null) 'notification_id': notifId,
          },
        )
        .then((_) { if (kDebugMode) print('[push] enviado a $userId'); })
        .catchError((e) { if (kDebugMode) print('[push] ERROR: $e'); });
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

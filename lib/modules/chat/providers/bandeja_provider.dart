import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../equipo/models/usuario.dart';

// ─── Preview de una conversación ────────────────────────────────────────────

class ConversacionPreview {
  final Usuario otro;
  final String? ultimoMensaje;
  final DateTime? ultimaFecha;
  final bool ultimoFueMio;
  final int sinLeer;

  const ConversacionPreview({
    required this.otro,
    this.ultimoMensaje,
    this.ultimaFecha,
    this.ultimoFueMio = false,
    this.sinLeer = 0,
  });

  bool get tieneMensajes => ultimaFecha != null;
}

// ─── Stream de la bandeja (todos los users + último mensaje + unread) ───────
//
// Usado por la pantalla /mensajes (lista completa) y por el bloque del
// dashboard (toma los 3 primeros). Combina:
//   1. Lista de usuarios activos del equipo (excluye al usuario actual).
//   2. Stream realtime de mensajes_chat para mantener el preview vivo.
// La RLS de Postgres garantiza que el stream solo entrega filas donde
// participa el usuario actual.

final bandejaProvider =
    StreamProvider.autoDispose<List<ConversacionPreview>>((ref) async* {
  final client = Supabase.instance.client;
  final yo = client.auth.currentUser?.id;
  if (yo == null) {
    yield const [];
    return;
  }

  try {
    final usersData = await client
        .from('users')
        .select()
        .eq('activo', true)
        .neq('id', yo)
        .order('nombre');
    final usuarios =
        (usersData as List).map((u) => Usuario.fromJson(u)).toList();

    final stream = client
        .from('mensajes_chat')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    await for (final rows in stream) {
      yield _construirBandeja(rows, usuarios, yo);
    }
  } catch (e) {
    if (kDebugMode) print('[bandeja] ERROR: $e');
    yield const [];
  }
});

List<ConversacionPreview> _construirBandeja(
  List<Map<String, dynamic>> rows,
  List<Usuario> usuarios,
  String yo,
) {
  final Map<String, Map<String, dynamic>> lastByUser = {};
  final Map<String, int> unreadByUser = {};

  for (final r in rows) {
    final deUserId = r['de_user_id'] as String?;
    final paraUserId = r['para_user_id'] as String?;
    if (deUserId == null || paraUserId == null) continue;

    String? otroId;
    if (deUserId == yo) {
      otroId = paraUserId;
    } else if (paraUserId == yo) {
      otroId = deUserId;
    }
    if (otroId == null) continue;

    final fecha = DateTime.tryParse(r['created_at'] as String? ?? '');
    if (fecha == null) continue;

    final cur = lastByUser[otroId];
    final curFecha = cur != null
        ? DateTime.tryParse(cur['created_at'] as String? ?? '')
        : null;
    if (curFecha == null || fecha.isAfter(curFecha)) {
      lastByUser[otroId] = r;
    }

    if (paraUserId == yo && (r['leido'] as bool? ?? false) == false) {
      unreadByUser[otroId] = (unreadByUser[otroId] ?? 0) + 1;
    }
  }

  final result = usuarios.map((u) {
    final last = lastByUser[u.id];
    final fecha = last != null
        ? DateTime.tryParse(last['created_at'] as String? ?? '')
        : null;
    return ConversacionPreview(
      otro: u,
      ultimoMensaje: last?['mensaje'] as String?,
      ultimaFecha: fecha,
      ultimoFueMio: last != null && last['de_user_id'] == yo,
      sinLeer: unreadByUser[u.id] ?? 0,
    );
  }).toList();

  result.sort((a, b) {
    if (a.ultimaFecha == null && b.ultimaFecha == null) {
      return a.otro.nombre.compareTo(b.otro.nombre);
    }
    if (a.ultimaFecha == null) return 1;
    if (b.ultimaFecha == null) return -1;
    return b.ultimaFecha!.compareTo(a.ultimaFecha!);
  });

  return result;
}

// Conversaciones que ya tienen al menos un mensaje (para el bloque compacto).
final conversacionesConMensajesProvider =
    Provider.autoDispose<AsyncValue<List<ConversacionPreview>>>((ref) {
  return ref.watch(bandejaProvider).whenData(
        (lista) => lista.where((c) => c.tieneMensajes).toList(),
      );
});

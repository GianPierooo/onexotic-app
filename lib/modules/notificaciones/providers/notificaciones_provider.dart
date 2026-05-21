import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Modelo -------------------------------------------------------------------

class Notificacion {
  final String id;
  final String userId;
  final String titulo;
  final String? mensaje;
  final String tipo;
  final bool leido;
  final DateTime createdAt;
  final String? referenciaId;

  const Notificacion({
    required this.id,
    required this.userId,
    required this.titulo,
    this.mensaje,
    required this.tipo,
    required this.leido,
    required this.createdAt,
    this.referenciaId,
  });

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static bool _asBool(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1' || s == 't') return true;
      if (s == 'false' || s == '0' || s == 'f') return false;
    }
    return fallback;
  }

  static DateTime _asDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: _asString(json['id']),
      userId: _asString(json['user_id']),
      titulo: () {
        final t = _asString(json['titulo']);
        return t.isEmpty ? '(sin título)' : t;
      }(),
      mensaje: _asNullableString(json['mensaje']),
      tipo: () {
        final t = _asString(json['tipo']);
        return t.isEmpty ? 'sistema' : t;
      }(),
      leido: _asBool(json['leido']),
      createdAt: _asDateTime(json['created_at']),
      referenciaId: _asNullableString(json['referencia_id']),
    );
  }
}

// --- Filtro activo ------------------------------------------------------------

final filtroNotifProvider = StateProvider<String>((_) => 'todas');

// --- Provider principal -------------------------------------------------------
// No observa authStateProvider · los errores de ese stream no deben
// propagarse aquí. El invalidate manual desde marcar/eliminar es suficiente.

final notificacionesAllProvider =
    FutureProvider<List<Notificacion>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    if (kDebugMode) print('[notificaciones] sin sesión activa ? retornando []');
    return [];
  }

  if (kDebugMode) print('[notificaciones] consultando para userId=$userId');

  final List<dynamic> rows = await client
      .from('notificaciones')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  if (kDebugMode) print('[notificaciones] recibidas ${rows.length} filas');

  final result = <Notificacion>[];
  for (final j in rows) {
    try {
      final map = (j is Map<String, dynamic>)
          ? j
          : Map<String, dynamic>.from(j as Map);
      result.add(Notificacion.fromJson(map));
    } catch (e, st) {
      if (kDebugMode) print('[notificaciones] parse error en fila: $e');
      if (kDebugMode) print('$st');
    }
  }
  if (kDebugMode) print('[notificaciones] parseadas ${result.length}/${rows.length}');
  return result;
});

// --- StreamProvider para badge en tiempo real ---------------------------------
// Si Realtime falla, el StreamProvider queda loading ? notifSinLeerProvider
// cae al fallback del FutureProvider. El stream jamás propaga error.

final notificacionesStreamProvider =
    StreamProvider<List<Notificacion>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(const <Notificacion>[]);

  return Supabase.instance.client
      .from('notificaciones')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map<List<Notificacion>>((rows) {
        final result = <Notificacion>[];
        for (final j in rows) {
          try {
            final map = Map<String, dynamic>.from(j);
            result.add(Notificacion.fromJson(map));
          } catch (e) {
            if (kDebugMode) print('[notif stream] parse error: $e');
          }
        }
        if (kDebugMode) print('[notif stream] emit: ${result.length} items');
        return result;
      })
      .transform(
        StreamTransformer<List<Notificacion>, List<Notificacion>>.fromHandlers(
          handleError: (e, st, sink) {
            if (kDebugMode) print('[notif stream] error → emitiendo []: $e');
            sink.add(const []);
          },
        ),
      );
});

// --- Badge sin leer -----------------------------------------------------------

final notifSinLeerProvider = Provider<int>((ref) {
  final streamVal = ref.watch(notificacionesStreamProvider);
  final fallbackVal = ref.watch(notificacionesAllProvider);
  final list = streamVal.valueOrNull ?? fallbackVal.valueOrNull;
  if (list == null) return 0;
  return list.where((n) => !n.leido).length;
});

// --- Marcar una como leída ----------------------------------------------------

class MarcarLeidaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MarcarLeidaNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> marcar(String id) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leido': true}).eq('id', id);
      _ref.invalidate(notificacionesAllProvider);
    } catch (e) {
      if (kDebugMode) print('[marcar leida] ERROR: $e');
    }
  }
}

final marcarLeidaProvider =
    StateNotifierProvider<MarcarLeidaNotifier, AsyncValue<void>>(
  (ref) => MarcarLeidaNotifier(ref),
);

// --- Marcar todas como leídas -------------------------------------------------

class MarcarTodasNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MarcarTodasNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> marcarTodas() async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leido': true})
          .eq('user_id', userId)
          .eq('leido', false);
      _ref.invalidate(notificacionesAllProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      if (kDebugMode) print('[marcar todas] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final marcarTodasProvider =
    StateNotifierProvider<MarcarTodasNotifier, AsyncValue<void>>(
  (ref) => MarcarTodasNotifier(ref),
);

// --- Eliminar notificación ----------------------------------------------------

class EliminarNotifNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EliminarNotifNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> eliminar(String id) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .delete()
          .eq('id', id);
      _ref.invalidate(notificacionesAllProvider);
    } catch (e) {
      if (kDebugMode) print('[eliminar notif] ERROR: $e');
    }
  }
}

final eliminarNotifProvider =
    StateNotifierProvider<EliminarNotifNotifier, AsyncValue<void>>(
  (ref) => EliminarNotifNotifier(ref),
);

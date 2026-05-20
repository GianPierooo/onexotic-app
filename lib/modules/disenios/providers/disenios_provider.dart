import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';
import '../models/disenio.dart';
import 'historial_provider.dart';

// ─── Filtro de tab ────────────────────────────────────────────────────────────

final diseniosTabProvider = StateProvider<String>((_) => 'todos');

// ─── Lista de diseños ─────────────────────────────────────────────────────────

final diseniosProvider = FutureProvider<List<Disenio>>((ref) async {
  final tab = ref.watch(diseniosTabProvider);
  final client = Supabase.instance.client;
  try {
    var query = client.from('disenios').select('*, drops(nombre)');
    if (tab != 'todos') {
      query = query.eq('estado', tab);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((j) => Disenio.fromJson(j)).toList();
  } catch (e, st) {
    if (kDebugMode) print('[disenios] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Contador de pendientes CEO (avance + revision) ───────────────────────────

final revisionesPendientesProvider = FutureProvider<int>((ref) async {
  ref.watch(diseniosProvider);
  try {
    final data = await Supabase.instance.client
        .from('disenios')
        .select('id')
        .inFilter('estado', ['avance', 'revision']);
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ─── Detalle de un diseño (por id) ────────────────────────────────────────────

final disenioDetalleProvider =
    FutureProvider.family<Disenio?, String>((ref, id) async {
  ref.watch(diseniosProvider);
  try {
    final data = await Supabase.instance.client
        .from('disenios')
        .select('*, drops(nombre)')
        .eq('id', id)
        .single();
    return Disenio.fromJson(data);
  } catch (e) {
    if (kDebugMode) print('[disenioDetalle] ERROR: $e');
    return null;
  }
});

// ─── Helper: notificación ─────────────────────────────────────────────────────

Future<void> notificarDisenio(
    String userId, String titulo, String mensaje) async {
  // pushNotif inserta en notificaciones Y envía push via Edge Function
  await pushNotif(
    userId: userId,
    titulo: titulo,
    mensaje: mensaje,
    tipo: 'disenio',
  );
}

Future<List<String>> idsAllCeos() async {
  try {
    final data = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('rol', 'ceo')
        .eq('activo', true);
    return (data as List).map((r) => r['id'] as String).toList();
  } catch (_) {
    return [];
  }
}

// ─── Helper: label legible de estado ─────────────────────────────────────────

String estadoLabel(String e) => switch (e) {
      'brief'     => 'Brief',
      'proceso'   => 'En proceso',
      'avance'    => 'Avance',
      'revision'  => 'Revisión',
      'aprobado'  => 'Aprobado',
      'rechazado' => 'Rechazado',
      'cancelado' => 'Cancelado',
      _           => e,
    };

// ─── Aprobar diseño ───────────────────────────────────────────────────────────

class AprobarDisenioNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AprobarDisenioNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> aprobar(String disenioId) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo, disenadora_id')
          .eq('id', disenioId)
          .single();
      final titulo = row['titulo'] as String;
      final disenadoraId = row['disenadora_id'] as String;

      String nombreAprobador = 'CEO';
      if (userId != null) {
        try {
          final u = await Supabase.instance.client
              .from('users').select('nombre').eq('id', userId).single();
          nombreAprobador = u['nombre'] as String? ?? 'CEO';
        } catch (_) {}
      }

      await Supabase.instance.client.from('disenios').update({
        'estado': 'aprobado',
        'aprobado_por': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disenioId);

      await notificarDisenio(disenadoraId, '¡Diseño aprobado!',
          '¡$titulo aprobado! Puede pasar a producción');

      await registrarHistorial(
        disenioId: disenioId,
        accion: 'Aprobado por $nombreAprobador',
        usuarioId: userId,
      );

      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[aprobar disenio] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final aprobarDisenioProvider =
    StateNotifierProvider<AprobarDisenioNotifier, AsyncValue<void>>(
  (ref) => AprobarDisenioNotifier(ref),
);

// ─── Rechazar diseño ──────────────────────────────────────────────────────────

class RechazarDisenioNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  RechazarDisenioNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> rechazar(String disenioId, String feedback) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo, disenadora_id')
          .eq('id', disenioId)
          .single();
      final titulo = row['titulo'] as String;
      final disenadoraId = row['disenadora_id'] as String;

      await Supabase.instance.client.from('disenios').update({
        'estado': 'rechazado',
        'feedback': feedback.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disenioId);

      await notificarDisenio(disenadoraId, 'Diseño rechazado',
          'Diseño rechazado: $titulo · Motivo: ${feedback.trim()}');

      await registrarHistorial(
        disenioId: disenioId,
        accion: 'Rechazado',
        descripcion: feedback.trim(),
        usuarioId: userId,
      );

      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[rechazar disenio] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final rechazarDisenioProvider =
    StateNotifierProvider<RechazarDisenioNotifier, AsyncValue<void>>(
  (ref) => RechazarDisenioNotifier(ref),
);

// ─── Cambiar estado + forzar (flujo completo + notificaciones) ────────────────

class CambiarEstadoNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CambiarEstadoNotifier(this._ref) : super(const AsyncValue.data(null));

  static String? nextEstado(String actual) => switch (actual) {
        'brief'    => 'proceso',
        'proceso'  => 'avance',
        'avance'   => 'revision',
        'revision' => 'aprobado',
        _          => null,
      };

  Future<bool> cambiar(String disenioId, String nuevoEstado,
      {bool subeVersion = false}) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo, disenadora_id, version, fecha_limite')
          .eq('id', disenioId)
          .single();
      final titulo = row['titulo'] as String;
      final disenadoraId = row['disenadora_id'] as String;
      final versionActual = (row['version'] as int?) ?? 1;
      final fechaLimite = row['fecha_limite'] as String?;

      final updates = <String, dynamic>{
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (subeVersion) {
        updates['version'] = versionActual + 1;
        updates['feedback'] = null;
      }

      await Supabase.instance.client
          .from('disenios')
          .update(updates)
          .eq('id', disenioId);

      await _enviarNotificacion(nuevoEstado, titulo, disenadoraId, fechaLimite);
      await _registrarCambioEstado(disenioId, nuevoEstado,
          subeVersion: subeVersion, version: versionActual + 1, usuarioId: userId);

      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[cambiarEstado] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Avance forzado por CEO sin esperar a la diseñadora
  Future<bool> forzar(String disenioId) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo, disenadora_id, estado')
          .eq('id', disenioId)
          .single();
      final titulo = row['titulo'] as String;
      final disenadoraId = row['disenadora_id'] as String;
      final estadoActual = row['estado'] as String;
      final siguiente = nextEstado(estadoActual);
      if (siguiente == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      String nombreCeo = 'CEO';
      if (userId != null) {
        try {
          final u = await Supabase.instance.client
              .from('users').select('nombre').eq('id', userId).single();
          nombreCeo = u['nombre'] as String? ?? 'CEO';
        } catch (_) {}
      }

      await Supabase.instance.client.from('disenios').update({
        'estado': siguiente,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disenioId);

      await registrarHistorial(
        disenioId: disenioId,
        accion: 'Avanzado manualmente a ${estadoLabel(siguiente)}',
        descripcion: 'Por $nombreCeo',
        usuarioId: userId,
      );

      await notificarDisenio(
        disenadoraId,
        'Estado cambiado: $titulo',
        'El estado fue cambiado manualmente a "${estadoLabel(siguiente)}" por $nombreCeo',
      );

      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[forzar estado] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> _enviarNotificacion(String estado, String titulo,
      String disenadoraId, String? fechaLimite) async {
    switch (estado) {
      case 'proceso':
        await notificarDisenio(
          disenadoraId,
          '¡Tu brief fue aprobado!',
          'Tu brief fue aprobado: $titulo · Puedes comenzar el diseño.',
        );
      case 'avance':
        break;
      case 'revision':
        final ceos = await idsAllCeos();
        for (final id in ceos) {
          await notificarDisenio(
              id, 'Diseño listo para aprobar', 'Diseño listo para aprobar: $titulo');
        }
      case 'cancelado':
        await notificarDisenio(
            disenadoraId, 'Diseño cancelado', 'Diseño cancelado: $titulo');
    }
  }

  Future<void> _registrarCambioEstado(String disenioId, String nuevoEstado,
      {bool subeVersion = false, int version = 1, String? usuarioId}) async {
    final accion = switch (nuevoEstado) {
      'proceso'   => 'Proceso iniciado',
      'avance'    => 'Avance subido',
      'revision'  => 'Enviado a revisión',
      'aprobado'  => 'Aprobado',
      'rechazado' => 'Rechazado',
      'cancelado' => 'Diseño cancelado',
      _           => 'Estado: $nuevoEstado',
    };
    final descripcion = subeVersion ? 'Nueva versión v$version' : null;
    await registrarHistorial(
      disenioId: disenioId,
      accion: accion,
      descripcion: descripcion,
      usuarioId: usuarioId,
    );
  }
}

final cambiarEstadoProvider =
    StateNotifierProvider<CambiarEstadoNotifier, AsyncValue<void>>(
  (ref) => CambiarEstadoNotifier(ref),
);

// ─── Cancelar diseño ──────────────────────────────────────────────────────────

class CancelarDisenioNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CancelarDisenioNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> cancelar(String disenioId) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo, disenadora_id')
          .eq('id', disenioId)
          .single();
      await Supabase.instance.client.from('disenios').update({
        'estado': 'cancelado',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disenioId);
      await notificarDisenio(row['disenadora_id'] as String, 'Diseño cancelado',
          'Diseño cancelado: ${row['titulo']}');
      await registrarHistorial(
        disenioId: disenioId,
        accion: 'Diseño cancelado',
        usuarioId: userId,
      );
      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[cancelar] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final cancelarDisenioProvider =
    StateNotifierProvider<CancelarDisenioNotifier, AsyncValue<void>>(
  (ref) => CancelarDisenioNotifier(ref),
);

// ─── Eliminar definitivamente ─────────────────────────────────────────────────

class EliminarDisenioNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EliminarDisenioNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> eliminar(String disenioId) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    try {
      try {
        final avances = await client
            .from('disenio_avances')
            .select('imagen_url')
            .eq('disenio_id', disenioId);
        for (final a in avances as List) {
          final url = a['imagen_url'] as String;
          final path = _extractPath(url, 'avances');
          if (path != null) {
            await client.storage.from('avances').remove([path]);
          }
        }
      } catch (_) {}

      try {
        final brief = await client
            .from('briefs')
            .select('referencias_urls')
            .eq('disenio_id', disenioId)
            .maybeSingle();
        if (brief != null) {
          final urls = (brief['referencias_urls'] as List?) ?? [];
          for (final url in urls) {
            final path = _extractPath(url as String, 'referencias');
            if (path != null) {
              await client.storage.from('referencias').remove([path]);
            }
          }
        }
      } catch (_) {}

      await client.from('disenios').delete().eq('id', disenioId);

      _ref.invalidate(diseniosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[eliminar disenio] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  String? _extractPath(String url, String bucket) {
    final marker = '/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx < 0) return null;
    return url.substring(idx + marker.length);
  }
}

final eliminarDisenioProvider =
    StateNotifierProvider<EliminarDisenioNotifier, AsyncValue<void>>(
  (ref) => EliminarDisenioNotifier(ref),
);

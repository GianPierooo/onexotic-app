import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/drop.dart';
import 'inventario_provider.dart';

final dropsInventarioProvider = FutureProvider<List<Drop>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('drops')
        .select('id, nombre, estado, concepto, fecha_lanzamiento')
        .order('created_at');
    return (data as List).map((j) => Drop.fromJson(j)).toList();
  } catch (e) {
    if (kDebugMode) print('[drops inventario] ERROR: $e');
    return [];
  }
});

// ─── Contar productos de un drop ─────────────────────────────────────────────

Future<int> contarProductosDelDrop(String dropId) async {
  try {
    final data = await Supabase.instance.client
        .from('productos')
        .select('id')
        .eq('drop_id', dropId);
    return (data as List).length;
  } catch (_) {
    return 0;
  }
}

// ─── Gestionar drops (crear / eliminar) ──────────────────────────────────────

class GestionarDropsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  GestionarDropsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> crear({
    required String nombre,
    String estado = 'planificacion',
    String? concepto,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('drops').insert({
        'nombre': nombre.trim(),
        'estado': estado,
        if (concepto != null && concepto.trim().isNotEmpty)
          'concepto': concepto.trim(),
      });
      _ref.invalidate(dropsInventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[drops] crear ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> editar(
    String id, {
    required String nombre,
    required String estado,
    String? concepto,
    DateTime? fechaLanzamiento,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('drops').update({
        'nombre': nombre.trim(),
        'estado': estado,
        'concepto': concepto?.trim().isNotEmpty == true ? concepto!.trim() : null,
        'fecha_lanzamiento':
            fechaLanzamiento?.toIso8601String().split('T').first,
      }).eq('id', id);
      _ref.invalidate(dropsInventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[drops] editar ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Solo elimina si no tiene productos. Retorna true si eliminó, false si tiene productos.
  Future<({bool ok, bool tieneProductos})> eliminarSiVacio(
      String dropId) async {
    final count = await contarProductosDelDrop(dropId);
    if (count > 0) return (ok: false, tieneProductos: true);
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('drops').delete().eq('id', dropId);
      _ref.invalidate(dropsInventarioProvider);
      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return (ok: true, tieneProductos: false);
    } catch (e) {
      if (kDebugMode) print('[drops] eliminar ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return (ok: false, tieneProductos: false);
    }
  }

  /// Desvincula todos los productos del drop y luego lo elimina.
  Future<bool> eliminar(String dropId) async {
    state = const AsyncValue.loading();
    try {
      // Desvincular productos (quedan con drop_id = null)
      await Supabase.instance.client
          .from('productos')
          .update({'drop_id': null}).eq('drop_id', dropId);
      // Eliminar el drop
      await Supabase.instance.client
          .from('drops')
          .delete()
          .eq('id', dropId);
      _ref.invalidate(dropsInventarioProvider);
      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[drops] eliminar ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final gestionarDropsProvider =
    StateNotifierProvider<GestionarDropsNotifier, AsyncValue<void>>(
  (ref) => GestionarDropsNotifier(ref),
);

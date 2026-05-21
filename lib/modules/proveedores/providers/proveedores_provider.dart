import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/proveedor.dart';

// ─── Filtros ──────────────────────────────────────────────────────────────────

final filtroTipoProveedorProvider = StateProvider<String?>((_) => null);
final mostrarInactivosProvider = StateProvider<bool>((_) => false);

// ─── Lista de proveedores con conteo de productos asociados ──────────────────

final proveedoresProvider = FutureProvider<List<Proveedor>>((ref) async {
  final tipo = ref.watch(filtroTipoProveedorProvider);
  final mostrarInactivos = ref.watch(mostrarInactivosProvider);
  final client = Supabase.instance.client;

  try {
    var query = client.from('proveedores').select();
    if (tipo != null) query = query.eq('tipo', tipo);
    if (!mostrarInactivos) query = query.eq('activo', true);

    final rows = await query.order('nombre', ascending: true);

    // Conteo de productos por proveedor (una sola query agregada)
    final productos = await client
        .from('productos')
        .select('proveedor_id')
        .not('proveedor_id', 'is', null);
    final conteo = <String, int>{};
    for (final p in productos as List) {
      final id = p['proveedor_id'] as String?;
      if (id != null) conteo[id] = (conteo[id] ?? 0) + 1;
    }

    return (rows as List)
        .map((j) => Proveedor.fromJson(
              Map<String, dynamic>.from(j),
              productos: conteo[j['id']] ?? 0,
            ))
        .toList();
  } catch (e, st) {
    if (kDebugMode) print('[proveedores] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Provider single para edición ─────────────────────────────────────────────

final proveedorByIdProvider =
    FutureProvider.family<Proveedor?, String>((ref, id) async {
  final lista = await ref.watch(proveedoresProvider.future);
  for (final p in lista) {
    if (p.id == id) return p;
  }
  return null;
});

// ─── CRUD ─────────────────────────────────────────────────────────────────────

class GestionarProveedorNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  GestionarProveedorNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> crear({
    required String nombre,
    String? contacto,
    String? telefono,
    String? tipo,
    int? rating,
    String? notas,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('proveedores').insert({
        'nombre': nombre.trim(),
        if (contacto != null && contacto.trim().isNotEmpty)
          'contacto': contacto.trim(),
        if (telefono != null && telefono.trim().isNotEmpty)
          'telefono': telefono.trim(),
        if (tipo != null) 'tipo': tipo,
        if (rating != null) 'rating': rating,
        if (notas != null && notas.trim().isNotEmpty) 'notas': notas.trim(),
        'activo': true,
      });
      _ref.invalidate(proveedoresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[crear proveedor] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> actualizar({
    required String id,
    required String nombre,
    String? contacto,
    String? telefono,
    String? tipo,
    int? rating,
    String? notas,
    bool? activo,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('proveedores').update({
        'nombre': nombre.trim(),
        'contacto': contacto?.trim().isEmpty == true ? null : contacto?.trim(),
        'telefono': telefono?.trim().isEmpty == true ? null : telefono?.trim(),
        'tipo': tipo,
        'rating': rating,
        'notas': notas?.trim().isEmpty == true ? null : notas?.trim(),
        if (activo != null) 'activo': activo,
      }).eq('id', id);
      _ref.invalidate(proveedoresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[actualizar proveedor] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    state = const AsyncValue.loading();
    try {
      // Soft delete: marcar como inactivo en vez de borrar.
      // Evita romper la FK opcional desde productos.proveedor_id si hubo asignación.
      await Supabase.instance.client
          .from('proveedores')
          .update({'activo': false}).eq('id', id);
      _ref.invalidate(proveedoresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[eliminar proveedor] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final gestionarProveedorProvider =
    StateNotifierProvider<GestionarProveedorNotifier, AsyncValue<void>>(
  (ref) => GestionarProveedorNotifier(ref),
);

// ─── Productos asociados a un proveedor ──────────────────────────────────────

final productosDeProveedorProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, proveedorId) async {
  try {
    final rows = await Supabase.instance.client
        .from('productos')
        .select('id, nombre, tipo, talla, stock, sku')
        .eq('proveedor_id', proveedorId)
        .order('nombre');
    return List<Map<String, dynamic>>.from(rows as List);
  } catch (e) {
    if (kDebugMode) print('[productos de proveedor] ERROR: $e');
    return [];
  }
});

// ─── Asignar / desasignar proveedor a producto ───────────────────────────────

class AsignarProveedorNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AsignarProveedorNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> asignar({
    required String productoId,
    required String? proveedorId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('productos')
          .update({'proveedor_id': proveedorId}).eq('id', productoId);
      _ref.invalidate(proveedoresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[asignar proveedor] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final asignarProveedorProvider =
    StateNotifierProvider<AsignarProveedorNotifier, AsyncValue<void>>(
  (ref) => AsignarProveedorNotifier(ref),
);

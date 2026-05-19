import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

// ─── Filtros ──────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((_) => '');
final dropFiltroInventarioProvider = StateProvider<String?>((_) => null);
final soloCriticosProvider = StateProvider<bool>((_) => false);

// ─── Lista de productos ───────────────────────────────────────────────────────

final inventarioProvider = FutureProvider<List<Producto>>((ref) async {
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final dropId = ref.watch(dropFiltroInventarioProvider);
  final soloCriticos = ref.watch(soloCriticosProvider);

  try {
    var query = Supabase.instance.client
        .from('productos')
        .select('*, drops(nombre)')
        .neq('estado', 'descontinuado');

    if (dropId != null) query = query.eq('drop_id', dropId);

    final data = await query.order('stock', ascending: true);
    var lista = (data as List).map((j) => Producto.fromJson(j)).toList();

    // Búsqueda client-side (nombre, SKU)
    if (q.isNotEmpty) {
      lista = lista.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            (p.sku?.toLowerCase().contains(q) ?? false) ||
            (p.dropNombre?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Filtro solo críticos
    if (soloCriticos) {
      lista = lista.where((p) => p.esCritico || p.esAgotado).toList();
    }

    return lista;
  } catch (e, st) {
    debugPrint('[inventario] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Agrupar por producto (nombre + dropId) ───────────────────────────────────

final inventarioAgrupadoProvider =
    Provider<AsyncValue<List<List<Producto>>>>((ref) {
  final inventarioAsync = ref.watch(inventarioProvider);
  return inventarioAsync.whenData((productos) => _agrupar(productos));
});

List<List<Producto>> _agrupar(List<Producto> productos) {
  final map = <String, List<Producto>>{};
  for (final p in productos) {
    final key = '${p.nombre}||${p.dropId ?? ''}||${p.tipo}';
    map.putIfAbsent(key, () => []).add(p);
  }
  // Ordenar cada grupo por talla y el mapa por stock mínimo del grupo
  final grupos = map.values.map((variantes) {
    variantes.sort(_tallaSorter);
    return variantes;
  }).toList();
  grupos.sort((a, b) {
    final minA = a.map((p) => p.stock).reduce((v, e) => v < e ? v : e);
    final minB = b.map((p) => p.stock).reduce((v, e) => v < e ? v : e);
    return minA.compareTo(minB);
  });
  return grupos;
}

int _tallaSorter(Producto a, Producto b) {
  const orden = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  return orden.indexOf(a.talla).compareTo(orden.indexOf(b.talla));
}

// ─── Conteo de críticos ───────────────────────────────────────────────────────

final stockCriticoCountProvider = Provider<AsyncValue<int>>((ref) {
  final inv = ref.watch(inventarioProvider);
  // Cuenta sin filtros de búsqueda: usa una query fresca
  return inv.whenData((lista) => lista
      .where((p) => p.stock <= p.stockMinimo && p.stock > 0)
      .length);
});

// ─── Editar stock ─────────────────────────────────────────────────────────────

class EditarStockNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EditarStockNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> actualizar(String productoId, int nuevoStock) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('productos').update({
        'stock': nuevoStock,
        'estado': nuevoStock == 0 ? 'agotado' : 'activo',
      }).eq('id', productoId);
      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[editar stock] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final editarStockProvider =
    StateNotifierProvider<EditarStockNotifier, AsyncValue<void>>(
  (ref) => EditarStockNotifier(ref),
);

// ─── Gestionar producto (agregar / editar / eliminar) ─────────────────────────

class GestionarProductoNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  GestionarProductoNotifier(this._ref) : super(const AsyncValue.data(null));

  // ── Agregar múltiples tallas a la vez ─────────────────────────────────────

  Future<bool> agregarMultiples({
    required String nombre,
    required String tipo,
    String? dropId,
    required String color,
    required int stockMinimo,
    required double costo,
    required double precioVenta,
    String? imagenUrl,
    required Map<String, int> tallaStock, // talla → stock
    String? disenioId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final skuBase = await _generarSkuBase(dropId, tipo);
      final rows = tallaStock.entries.map((e) => {
        'nombre': nombre,
        'tipo': tipo,
        'drop_id': dropId,
        'talla': e.key,
        'color': color,
        'stock': e.value,
        'stock_minimo': stockMinimo,
        'costo': costo,
        'precio_venta': precioVenta,
        if (imagenUrl != null) 'imagen_url': imagenUrl,
        if (disenioId != null) 'disenio_id': disenioId,
        'sku': '$skuBase-${e.key}',
        'estado': e.value > 0 ? 'activo' : 'agotado',
      }).toList();
      await Supabase.instance.client.from('productos').insert(rows);
      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[gestionar producto] agregarMultiples ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // ── Editar grupo de variantes (todas las tallas) ──────────────────────────

  Future<bool> editarMultiples({
    required List<Producto> existentes,
    required String nombre,
    required String tipo,
    String? dropId,
    required String color,
    required int stockMinimo,
    required double costo,
    required double precioVenta,
    String? imagenUrl,
    required Map<String, int> tallaStock,
  }) async {
    state = const AsyncValue.loading();
    try {
      final porTalla = {for (final p in existentes) p.talla: p};
      final skuBase = _extraerSkuBase(existentes) ??
          await _generarSkuBase(dropId, tipo);

      for (final entry in tallaStock.entries) {
        final talla = entry.key;
        final stock = entry.value;
        final campos = {
          'nombre': nombre,
          'tipo': tipo,
          'drop_id': dropId,
          'talla': talla,
          'color': color,
          'stock': stock,
          'stock_minimo': stockMinimo,
          'costo': costo,
          'precio_venta': precioVenta,
          'estado': stock > 0 ? 'activo' : 'agotado',
          if (imagenUrl != null) 'imagen_url': imagenUrl,
        };
        final existente = porTalla[talla];
        if (existente != null) {
          await Supabase.instance.client
              .from('productos')
              .update(campos)
              .eq('id', existente.id);
        } else {
          await Supabase.instance.client.from('productos').insert({
            ...campos,
            'sku': '$skuBase-$talla',
          });
        }
      }

      // Eliminar tallas que quedaron en 0 (removidas del formulario)
      for (final talla in porTalla.keys) {
        if (!tallaStock.containsKey(talla)) {
          await Supabase.instance.client
              .from('productos')
              .delete()
              .eq('id', porTalla[talla]!.id);
        }
      }

      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[gestionar producto] editarMultiples ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // ── Eliminar grupo completo ────────────────────────────────────────────────

  Future<bool> eliminar(List<String> ids) async {
    state = const AsyncValue.loading();
    try {
      for (final id in ids) {
        await Supabase.instance.client.from('productos').delete().eq('id', id);
      }
      _ref.invalidate(inventarioProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[gestionar producto] eliminar ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // ── Helpers SKU ───────────────────────────────────────────────────────────

  /// Genera la base del SKU: DROP-TIPO-NNN  (sin talla)
  Future<String> _generarSkuBase(String? dropId, String tipo) async {
    String dropAbrev = 'XX';
    if (dropId != null) {
      try {
        final data = await Supabase.instance.client
            .from('drops')
            .select('nombre')
            .eq('id', dropId)
            .single();
        dropAbrev = _dropAbrev(data['nombre'] as String? ?? '');
      } catch (_) {}
    }
    final tipoAbrev = _tipoAbrev(tipo);
    final prefix = '$dropAbrev-$tipoAbrev-';
    try {
      final rows = await Supabase.instance.client
          .from('productos')
          .select('sku')
          .like('sku', '$prefix%');
      int maxNum = 0;
      for (final row in rows as List) {
        final sku = row['sku'] as String?;
        if (sku != null && sku.startsWith(prefix)) {
          // Soporte para formato antiguo (sin talla) y nuevo (con talla)
          final numStr = sku.substring(prefix.length).split('-').first;
          final num = int.tryParse(numStr) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }
      return '$prefix${(maxNum + 1).toString().padLeft(3, '0')}';
    } catch (_) {
      return '${prefix}001';
    }
  }

  /// Extrae la base del SKU de variantes existentes: DROP-TIPO-NNN
  String? _extraerSkuBase(List<Producto> existentes) {
    for (final p in existentes) {
      final sku = p.sku;
      if (sku == null) continue;
      final lastDash = sku.lastIndexOf('-');
      if (lastDash > 0) return sku.substring(0, lastDash);
    }
    return null;
  }

  String _dropAbrev(String nombre) {
    final upper = nombre.toUpperCase().trim();
    if (upper == 'EXOTIC0') return 'EX';
    if (upper == 'Ñ' || upper == 'N') return 'N';
    if (upper.startsWith('DROP ')) {
      final rest = nombre.substring(5).trim().replaceAll(RegExp(r'\D'), '');
      return 'D${rest.isNotEmpty ? rest : 'X'}';
    }
    final clean = nombre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return (clean.length >= 2 ? clean.substring(0, 2) : clean).toUpperCase();
  }

  String _tipoAbrev(String tipo) => switch (tipo) {
    'polo'      => 'PL',
    'short'     => 'SH',
    'pantalon'  => 'PT',
    'polera'    => 'PO',
    'accesorio' => 'AC',
    _           => tipo.length >= 2
        ? tipo.substring(0, 2).toUpperCase()
        : tipo.toUpperCase(),
  };
}

final gestionarProductoProvider =
    StateNotifierProvider<GestionarProductoNotifier, AsyncValue<void>>(
  (ref) => GestionarProductoNotifier(ref),
);

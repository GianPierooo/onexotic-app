import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Modelo agregado ──────────────────────────────────────────────────────────

class AnaliticasData {
  // Inventario
  final double valorTotalInventario; // SUM(stock * precio_venta)
  final double margenPotencialTotal; // SUM(stock * (precio - costo))
  final int productosCriticos;
  final int productosSanos;
  final int productosAgotados;
  final Map<String, int> productosPorTipo;
  final List<DropAnalitica> ventasPorDrop;

  // Equipo / asistencia
  final List<DiaAsistencia> asistenciaSemanal;
  final double porcentajeAsistenciaSemanal;

  // Tareas
  final Map<String, TareasArea> tareasPorArea;
  final int totalTareasCompletadas;
  final int totalTareasPendientes;

  // Diseños
  final Map<String, int> disenosPorEstado;
  final int disenosAprobadosMes;

  const AnaliticasData({
    required this.valorTotalInventario,
    required this.margenPotencialTotal,
    required this.productosCriticos,
    required this.productosSanos,
    required this.productosAgotados,
    required this.productosPorTipo,
    required this.ventasPorDrop,
    required this.asistenciaSemanal,
    required this.porcentajeAsistenciaSemanal,
    required this.tareasPorArea,
    required this.totalTareasCompletadas,
    required this.totalTareasPendientes,
    required this.disenosPorEstado,
    required this.disenosAprobadosMes,
  });
}

class DropAnalitica {
  final String dropId;
  final String nombre;
  final int productos;
  final double valorInventario;
  final double margenPotencial;

  const DropAnalitica({
    required this.dropId,
    required this.nombre,
    required this.productos,
    required this.valorInventario,
    required this.margenPotencial,
  });
}

class DiaAsistencia {
  final DateTime fecha;
  final int presentes;
  final int totalEquipo;

  const DiaAsistencia({
    required this.fecha,
    required this.presentes,
    required this.totalEquipo,
  });

  double get porcentaje =>
      totalEquipo == 0 ? 0 : (presentes / totalEquipo) * 100;
}

class TareasArea {
  final int completadas;
  final int pendientes;
  const TareasArea({required this.completadas, required this.pendientes});

  int get total => completadas + pendientes;
  double get porcentajeCompletadas =>
      total == 0 ? 0 : (completadas / total) * 100;
}

// ─── Provider principal ───────────────────────────────────────────────────────

final analiticasProvider = FutureProvider<AnaliticasData>((ref) async {
  final client = Supabase.instance.client;

  try {
    // ── 1. Productos activos (con drop) ───────────────────────────────────────
    final productos = await client
        .from('productos')
        .select(
            'stock, stock_minimo, costo, precio_venta, tipo, drop_id, drops(nombre, id)')
        .neq('estado', 'descontinuado');

    double valorTotal = 0;
    double margenTotal = 0;
    int criticos = 0, sanos = 0, agotados = 0;
    final porTipo = <String, int>{};
    final dropAgg = <String, _DropAgg>{};

    for (final p in productos as List) {
      final stock = (p['stock'] as num?)?.toInt() ?? 0;
      final stockMin = (p['stock_minimo'] as num?)?.toInt() ?? 0;
      final costo = (p['costo'] as num?)?.toDouble() ?? 0;
      final precio = (p['precio_venta'] as num?)?.toDouble() ?? 0;
      final tipo = p['tipo'] as String? ?? 'otro';
      final dropMap = p['drops'] as Map?;
      final dropId = (dropMap?['id'] ?? p['drop_id']) as String?;
      final dropNombre = dropMap?['nombre'] as String?;

      valorTotal += stock * precio;
      margenTotal += stock * (precio - costo);

      if (stock == 0) {
        agotados++;
      } else if (stock <= stockMin) {
        criticos++;
      } else {
        sanos++;
      }

      porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;

      if (dropId != null) {
        final agg = dropAgg.putIfAbsent(
            dropId, () => _DropAgg(nombre: dropNombre ?? 'Sin nombre'));
        agg.productos++;
        agg.valor += stock * precio;
        agg.margen += stock * (precio - costo);
      }
    }

    final ventasPorDrop = dropAgg.entries
        .map((e) => DropAnalitica(
              dropId: e.key,
              nombre: e.value.nombre,
              productos: e.value.productos,
              valorInventario: e.value.valor,
              margenPotencial: e.value.margen,
            ))
        .toList()
      ..sort((a, b) => b.valorInventario.compareTo(a.valorInventario));

    // ── 2. Asistencia últimos 7 días ──────────────────────────────────────────
    final hoy = DateTime.now();
    final hace7 = hoy.subtract(const Duration(days: 6));
    final desdeStr = _dateStr(hace7);

    final usuariosAct = await client
        .from('users')
        .select('id')
        .eq('activo', true);
    final totalEquipo = (usuariosAct as List).length;

    final asistencias = await client
        .from('asistencia')
        .select('fecha, presente, user_id')
        .gte('fecha', desdeStr)
        .eq('reunion_tipo', 'diaria');

    final porFecha = <String, Set<String>>{};
    for (final a in asistencias as List) {
      if (a['presente'] != true) continue;
      final fecha = a['fecha'] as String?;
      final userId = a['user_id'] as String?;
      if (fecha == null || userId == null) continue;
      porFecha.putIfAbsent(fecha, () => <String>{}).add(userId);
    }

    final asistenciaSemanal = <DiaAsistencia>[];
    int sumPresentes = 0;
    for (int i = 0; i < 7; i++) {
      final dia = hace7.add(Duration(days: i));
      final key = _dateStr(dia);
      final presentes = porFecha[key]?.length ?? 0;
      sumPresentes += presentes;
      asistenciaSemanal.add(DiaAsistencia(
        fecha: dia,
        presentes: presentes,
        totalEquipo: totalEquipo,
      ));
    }

    final maxPosible = totalEquipo * 7;
    final pctSemanal =
        maxPosible == 0 ? 0.0 : (sumPresentes / maxPosible) * 100;

    // ── 3. Tareas por área ────────────────────────────────────────────────────
    final tareas =
        await client.from('tareas').select('area, completado');
    final tareasPorArea = <String, _TareaCount>{};
    int totalComp = 0, totalPend = 0;
    for (final t in tareas as List) {
      final area = t['area'] as String? ?? 'otra';
      final c = t['completado'] == true;
      final agg = tareasPorArea.putIfAbsent(area, () => _TareaCount());
      if (c) {
        agg.completadas++;
        totalComp++;
      } else {
        agg.pendientes++;
        totalPend++;
      }
    }

    // ── 4. Diseños por estado + aprobados último mes ─────────────────────────
    final disenios =
        await client.from('disenios').select('estado, updated_at');
    final disenosEstado = <String, int>{};
    int aprobadosMes = 0;
    final hace30 = hoy.subtract(const Duration(days: 30));
    for (final d in disenios as List) {
      final estado = d['estado'] as String? ?? 'desconocido';
      disenosEstado[estado] = (disenosEstado[estado] ?? 0) + 1;
      if (estado == 'aprobado') {
        final updatedStr = d['updated_at'] as String?;
        if (updatedStr != null) {
          final updated = DateTime.tryParse(updatedStr);
          if (updated != null && updated.isAfter(hace30)) aprobadosMes++;
        }
      }
    }

    return AnaliticasData(
      valorTotalInventario: valorTotal,
      margenPotencialTotal: margenTotal,
      productosCriticos: criticos,
      productosSanos: sanos,
      productosAgotados: agotados,
      productosPorTipo: porTipo,
      ventasPorDrop: ventasPorDrop,
      asistenciaSemanal: asistenciaSemanal,
      porcentajeAsistenciaSemanal: pctSemanal,
      tareasPorArea: tareasPorArea.map((k, v) => MapEntry(
            k,
            TareasArea(
              completadas: v.completadas,
              pendientes: v.pendientes,
            ),
          )),
      totalTareasCompletadas: totalComp,
      totalTareasPendientes: totalPend,
      disenosPorEstado: disenosEstado,
      disenosAprobadosMes: aprobadosMes,
    );
  } catch (e, st) {
    if (kDebugMode) print('[analiticas] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Helpers internos ────────────────────────────────────────────────────────

class _DropAgg {
  final String nombre;
  int productos = 0;
  double valor = 0;
  double margen = 0;
  _DropAgg({required this.nombre});
}

class _TareaCount {
  int completadas = 0;
  int pendientes = 0;
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

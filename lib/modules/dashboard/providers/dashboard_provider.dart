import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_provider.dart';

// ─── Perfil del usuario autenticado ──────────────────────────────────────────
// Observa el stream de auth para re-ejecutarse al hacer login/logout
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Rerun cuando cambia el estado de autenticación
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('[currentUser] sin sesión activa');
    return null;
  }
  try {
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    debugPrint('[currentUser] cargado: ${data?['nombre']} / ${data?['rol']}');
    return data;
  } catch (e) {
    debugPrint('[currentUser] ERROR: $e');
    rethrow;
  }
});

// ─── Modelo de métricas ───────────────────────────────────────────────────────
class DashboardData {
  final int stockCritico;
  final int tareasPendientes;
  final int presentesHoy;
  final int totalEquipo;
  final int diasProximoDrop;
  final String? nombreProximoDrop;
  final DateTime? fechaProximoDrop;

  const DashboardData({
    required this.stockCritico,
    required this.tareasPendientes,
    required this.presentesHoy,
    required this.totalEquipo,
    required this.diasProximoDrop,
    this.nombreProximoDrop,
    this.fechaProximoDrop,
  });
}

// ─── Métricas del dashboard ───────────────────────────────────────────────────
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final today =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  try {
    // 1. Stock crítico
    debugPrint('[dashboard] consultando productos...');
    final productos = await client
        .from('productos')
        .select('stock, stock_minimo')
        .eq('estado', 'activo');
    debugPrint('[dashboard] productos OK: ${productos.length} rows');

    final stockCritico = productos.where((p) {
      final stock = (p['stock'] as num).toInt();
      final minimo = (p['stock_minimo'] as num).toInt();
      return stock <= minimo;
    }).length;

    // 2. Tareas pendientes
    debugPrint('[dashboard] consultando tareas...');
    final tareas = await client
        .from('tareas')
        .select('id')
        .eq('completado', false);
    debugPrint('[dashboard] tareas OK: ${tareas.length} rows');
    final tareasPendientes = tareas.length;

    // 3. Asistencia hoy
    debugPrint('[dashboard] consultando asistencia...');
    final asistencia = await client
        .from('asistencia')
        .select('presente')
        .eq('fecha', today)
        .eq('reunion_tipo', 'diaria');
    debugPrint('[dashboard] asistencia OK: ${asistencia.length} rows');
    final presentesHoy =
        asistencia.where((a) => a['presente'] == true).length;

    // 4. Total equipo activo
    final usuarios = await client
        .from('users')
        .select('id')
        .eq('activo', true);
    final totalEquipo = usuarios.length;
    debugPrint('[dashboard] equipo: $totalEquipo usuarios');

    // 5. Próximo drop:
    //    Primera búsqueda: planificacion/produccion con fecha futura (gte skips nulls).
    //    Fallback: planificacion/produccion sin importar si tienen fecha o no.
    debugPrint('[dashboard] consultando drops...');
    var rawDrops = await client
        .from('drops')
        .select('nombre, fecha_lanzamiento, estado')
        .inFilter('estado', ['planificacion', 'produccion'])
        .gte('fecha_lanzamiento', today)
        .order('fecha_lanzamiento', ascending: true)
        .limit(5) as List;

    if (rawDrops.isEmpty) {
      rawDrops = await client
          .from('drops')
          .select('nombre, fecha_lanzamiento, estado')
          .inFilter('estado', ['planificacion', 'produccion'])
          .order('created_at', ascending: false)
          .limit(5) as List;
    }
    debugPrint('[dashboard] drops OK: ${rawDrops.length} rows');

    final dropsValidos = rawDrops;

    int diasProximoDrop = 0;
    String? nombreDrop;
    DateTime? fechaDrop;

    if (dropsValidos.isNotEmpty) {
      nombreDrop = dropsValidos.first['nombre'] as String?;
      final fechaStr = dropsValidos.first['fecha_lanzamiento'] as String?;
      if (fechaStr != null) {
        fechaDrop = DateTime.tryParse(fechaStr);
        if (fechaDrop != null) {
          final hoy = DateTime(now.year, now.month, now.day);
          diasProximoDrop = fechaDrop.difference(hoy).inDays;
        }
      }
    }

    debugPrint('[dashboard] métricas: stock=$stockCritico, tareas=$tareasPendientes, presentes=$presentesHoy/$totalEquipo, drop=${diasProximoDrop}d');

    return DashboardData(
      stockCritico: stockCritico,
      tareasPendientes: tareasPendientes,
      presentesHoy: presentesHoy,
      totalEquipo: totalEquipo,
      diasProximoDrop: diasProximoDrop,
      nombreProximoDrop: nombreDrop,
      fechaProximoDrop: fechaDrop,
    );
  } catch (e, st) {
    debugPrint('[dashboard] ERROR en dashboardDataProvider: $e');
    debugPrint(st.toString());
    rethrow;
  }
});

// ─── Notificaciones recientes ─────────────────────────────────────────────────
final notificacionesRecientesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  try {
    final data = await Supabase.instance.client
        .from('notificaciones')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(3);
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('[notif] ERROR: $e');
    return [];
  }
});

// notifSinLeerProvider se define en notificaciones/providers/notificaciones_provider.dart

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
    if (kDebugMode) print('[currentUser] sin sesión activa');
    return null;
  }
  try {
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (kDebugMode) print('[currentUser] cargado: ${data?['nombre']} / ${data?['rol']}');
    return data;
  } catch (e) {
    if (kDebugMode) print('[currentUser] ERROR: $e');
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
    if (kDebugMode) print('[dashboard] consultando productos...');
    final productos = await client
        .from('productos')
        .select('stock, stock_minimo')
        .eq('estado', 'activo');
    if (kDebugMode) print('[dashboard] productos OK: ${productos.length} rows');

    final stockCritico = productos.where((p) {
      final stock = (p['stock'] as num).toInt();
      final minimo = (p['stock_minimo'] as num).toInt();
      return stock <= minimo;
    }).length;

    // 2. Tareas pendientes
    if (kDebugMode) print('[dashboard] consultando tareas...');
    final tareas = await client
        .from('tareas')
        .select('id')
        .eq('completado', false);
    if (kDebugMode) print('[dashboard] tareas OK: ${tareas.length} rows');
    final tareasPendientes = tareas.length;

    // 3. Asistencia hoy
    if (kDebugMode) print('[dashboard] consultando asistencia...');
    final asistencia = await client
        .from('asistencia')
        .select('presente')
        .eq('fecha', today)
        .eq('reunion_tipo', 'diaria');
    if (kDebugMode) print('[dashboard] asistencia OK: ${asistencia.length} rows');
    final presentesHoy =
        asistencia.where((a) => a['presente'] == true).length;

    // 4. Total equipo activo
    final usuarios = await client
        .from('users')
        .select('id')
        .eq('activo', true);
    final totalEquipo = usuarios.length;
    if (kDebugMode) print('[dashboard] equipo: $totalEquipo usuarios');

    // 5. Próximo drop:
    //    Primera búsqueda: planificacion/produccion con fecha futura (gte skips nulls).
    //    Fallback: planificacion/produccion sin importar si tienen fecha o no.
    if (kDebugMode) print('[dashboard] consultando drops...');
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
    if (kDebugMode) print('[dashboard] drops OK: ${rawDrops.length} rows');

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

    if (kDebugMode) print('[dashboard] métricas: stock=$stockCritico, tareas=$tareasPendientes, presentes=$presentesHoy/$totalEquipo, drop=${diasProximoDrop}d');

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
    if (kDebugMode) print('[dashboard] ERROR en dashboardDataProvider: $e');
    if (kDebugMode) print(st.toString());
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
    if (kDebugMode) print('[notif] ERROR: $e');
    return [];
  }
});

// notifSinLeerProvider se define en notificaciones/providers/notificaciones_provider.dart

// ─── Dashboard exclusivo para diseñadora ─────────────────────────────────────

class DashboardDisenoraData {
  final List<Map<String, dynamic>> disenosActivos; // proceso|avance|revision
  final List<Map<String, dynamic>> briefsPendientes; // estado = brief
  final String? ultimoFeedback;
  final String? ultimoFeedbackTitulo;

  const DashboardDisenoraData({
    required this.disenosActivos,
    required this.briefsPendientes,
    this.ultimoFeedback,
    this.ultimoFeedbackTitulo,
  });

  int get disenosCount => disenosActivos.length;
  int get briefsCount => briefsPendientes.length;

  Map<String, dynamic>? get proximaEntrega {
    final todas = [...disenosActivos, ...briefsPendientes]
        .where((d) => d['fecha_limite'] != null)
        .toList();
    if (todas.isEmpty) return null;
    todas.sort((a, b) =>
        (a['fecha_limite'] as String).compareTo(b['fecha_limite'] as String));
    return todas.first;
  }
}

final dashboardDisenoraProvider =
    FutureProvider<DashboardDisenoraData>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return const DashboardDisenoraData(
        disenosActivos: [], briefsPendientes: []);
  }
  final client = Supabase.instance.client;
  try {
    final activos = await client
        .from('disenios')
        .select('id, titulo, estado, fecha_limite, version, drops(nombre)')
        .eq('disenadora_id', userId)
        .inFilter('estado', ['proceso', 'avance', 'revision'])
        .order('fecha_limite', ascending: true, nullsFirst: false);

    final briefs = await client
        .from('disenios')
        .select('id, titulo, estado, fecha_limite, version, drops(nombre)')
        .eq('disenadora_id', userId)
        .eq('estado', 'brief')
        .order('fecha_limite', ascending: true, nullsFirst: false);

    final rechazados = await client
        .from('disenios')
        .select('titulo, feedback')
        .eq('disenadora_id', userId)
        .eq('estado', 'rechazado')
        .not('feedback', 'is', null)
        .order('updated_at', ascending: false)
        .limit(1);

    final ultimo = (rechazados as List).isNotEmpty ? rechazados.first : null;

    return DashboardDisenoraData(
      disenosActivos:
          List<Map<String, dynamic>>.from(activos as List),
      briefsPendientes:
          List<Map<String, dynamic>>.from(briefs as List),
      ultimoFeedback: ultimo?['feedback'] as String?,
      ultimoFeedbackTitulo: ultimo?['titulo'] as String?,
    );
  } catch (e) {
    rethrow;
  }
});

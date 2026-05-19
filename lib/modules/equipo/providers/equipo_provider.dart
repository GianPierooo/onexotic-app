import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bono.dart';
import '../models/usuario.dart';

// ─── Model con stats de asistencia ───────────────────────────────────────────

class UsuarioConStats {
  final Usuario usuario;
  final double asistenciaMensual; // 0.0 – 100.0

  const UsuarioConStats({
    required this.usuario,
    required this.asistenciaMensual,
  });
}

// ─── Lista del equipo con % asistencia ───────────────────────────────────────

final equipoProvider = FutureProvider<List<UsuarioConStats>>((ref) async {
  final client = Supabase.instance.client;

  try {
    // 1. Todos los usuarios activos
    final usersData = await client
        .from('users')
        .select()
        .eq('activo', true)
        .order('nombre');

    // 2. Asistencia del mes actual (todos los usuarios, una sola query)
    final now = DateTime.now();
    final primerDia =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

    final asistData = await client
        .from('asistencia')
        .select('user_id, presente')
        .gte('fecha', primerDia);

    // 3. Agrupar asistencias por usuario
    final Map<String, List<bool>> porUsuario = {};
    for (final a in asistData as List) {
      final uid = a['user_id'] as String;
      porUsuario.putIfAbsent(uid, () => []).add(a['presente'] as bool? ?? false);
    }

    return (usersData as List).map((u) {
      final usuario = Usuario.fromJson(u);
      final asistencias = porUsuario[usuario.id] ?? [];
      final presentes = asistencias.where((p) => p).length;
      final pct = asistencias.isEmpty
          ? 0.0
          : presentes / asistencias.length * 100.0;
      return UsuarioConStats(usuario: usuario, asistenciaMensual: pct);
    }).toList();
  } catch (e, st) {
    debugPrint('[equipo] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Bonos del trimestre actual ───────────────────────────────────────────────

final bonosProvider = FutureProvider<List<Bono>>((ref) async {
  try {
    final now = DateTime.now();
    final q = ((now.month - 1) ~/ 3) + 1;
    final periodo = 'Q$q-${now.year}';

    final data = await Supabase.instance.client
        .from('bonos')
        .select()
        .eq('periodo', periodo)
        .order('created_at', ascending: false);

    return (data as List).map((j) => Bono.fromJson(j)).toList();
  } catch (e) {
    debugPrint('[bonos] ERROR: $e');
    return [];
  }
});

// ─── Total bonos del trimestre ────────────────────────────────────────────────

final totalBonosProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(bonosProvider).whenData(
    (bonos) => bonos.fold(0.0, (sum, b) => sum + b.monto),
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/providers/dashboard_provider.dart';

// ─── ThemeMode derivado del campo tema del usuario ────────────────────────────

final themeModeProvider = Provider<ThemeMode>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  // valueOrNull preserva el valor previo durante el re-fetch (invalidate),
  // evitando el flash dark→light→dark al cambiar el tema.
  final temaRaw = (userAsync.valueOrNull?['tema'] as String? ?? 'dark')
      .toLowerCase()
      .trim();
  // Acepta 'light'/'claro' y 'dark'/'oscuro'.
  final isLight = temaRaw == 'light' || temaRaw == 'claro';
  return isLight ? ThemeMode.light : ThemeMode.dark;
});

// ─── Estadísticas del perfil ──────────────────────────────────────────────────

class PerfilStats {
  final double asistenciaPct;
  final int tareasCompletadas;
  final int disenosAprobados;
  final int rachaActual;

  const PerfilStats({
    required this.asistenciaPct,
    required this.tareasCompletadas,
    required this.disenosAprobados,
    required this.rachaActual,
  });
}

final perfilStatsProvider = FutureProvider<PerfilStats>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return const PerfilStats(
      asistenciaPct: 0,
      tareasCompletadas: 0,
      disenosAprobados: 0,
      rachaActual: 0,
    );
  }
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final primerDia =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

  try {
    // 1. Asistencia este mes
    final asistData = await client
        .from('asistencia')
        .select('presente')
        .eq('user_id', userId)
        .gte('fecha', primerDia);
    final total = (asistData as List).length;
    final presentes = asistData.where((a) => a['presente'] == true).length;
    final asistPct = total == 0 ? 0.0 : presentes / total * 100.0;

    // 2. Tareas completadas (historial completo)
    final tareasData = await client
        .from('tareas')
        .select('id')
        .eq('asignado_a', userId)
        .eq('completado', true);
    final tareasCompletadas = (tareasData as List).length;

    // 3. Diseños aprobados (como diseñadora o CEO)
    final disenosData = await client
        .from('disenios')
        .select('id')
        .eq('estado', 'aprobado');
    final disenosAprobados = (disenosData as List).length;

    // 4. Racha: días consecutivos con asistencia presente (hacia atrás desde hoy)
    final rachaData = await client
        .from('asistencia')
        .select('fecha, presente')
        .eq('user_id', userId)
        .eq('presente', true)
        .order('fecha', ascending: false)
        .limit(60);

    final fechas = (rachaData as List)
        .map((a) => DateTime.tryParse(a['fecha'] as String? ?? ''))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    int racha = 0;
    DateTime check = DateTime(now.year, now.month, now.day);
    while (fechas.contains(check)) {
      racha++;
      check = check.subtract(const Duration(days: 1));
    }

    return PerfilStats(
      asistenciaPct: asistPct,
      tareasCompletadas: tareasCompletadas,
      disenosAprobados: disenosAprobados,
      rachaActual: racha,
    );
  } catch (e) {
    debugPrint('[perfilStats] ERROR: $e');
    return const PerfilStats(
      asistenciaPct: 0,
      tareasCompletadas: 0,
      disenosAprobados: 0,
      rachaActual: 0,
    );
  }
});

// ─── Actualizar tema ──────────────────────────────────────────────────────────

class ActualizarTemaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ActualizarTemaNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> cambiar(String nuevoTema) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('users')
          .update({'tema': nuevoTema}).eq('id', userId);
      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('[actualizar tema] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final actualizarTemaProvider =
    StateNotifierProvider<ActualizarTemaNotifier, AsyncValue<void>>(
  (ref) => ActualizarTemaNotifier(ref),
);

// ─── Cerrar sesión ────────────────────────────────────────────────────────────

Future<void> cerrarSesion(WidgetRef ref) async {
  await Supabase.instance.client.auth.signOut();
  ref.invalidate(currentUserProvider);
}

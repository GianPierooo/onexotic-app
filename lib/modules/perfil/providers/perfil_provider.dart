import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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

    // 3. Diseños aprobados propios del usuario
    final disenosData = await client
        .from('disenios')
        .select('id')
        .eq('disenadora_id', userId)
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
    if (kDebugMode) print('[perfilStats] ERROR: $e');
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
      if (kDebugMode) print('[actualizar tema] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final actualizarTemaProvider =
    StateNotifierProvider<ActualizarTemaNotifier, AsyncValue<void>>(
  (ref) => ActualizarTemaNotifier(ref),
);

// ─── Actualizar perfil propio ─────────────────────────────────────────────────

class ActualizarPerfilNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ActualizarPerfilNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> actualizar({
    required String nombre,
    String? apellido,
    String? telefono,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = AsyncValue.error('Sin sesión activa', StackTrace.current);
      return false;
    }
    try {
      final updates = <String, dynamic>{'nombre': nombre.trim()};
      updates['apellido'] =
          (apellido?.trim().isNotEmpty ?? false) ? apellido!.trim() : null;
      updates['telefono'] =
          (telefono?.trim().isNotEmpty ?? false) ? telefono!.trim() : null;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', userId);

      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<String?> subirAvatar(Uint8List bytes, String ext) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final client = Supabase.instance.client;
      final path = 'avatars/$userId/avatar.$ext';
      await client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      // Añade timestamp para forzar cache-bust en la imagen
      final base = client.storage.from('avatars').getPublicUrl(path);
      return '$base?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }
}

final actualizarPerfilProvider =
    StateNotifierProvider<ActualizarPerfilNotifier, AsyncValue<void>>(
  (ref) => ActualizarPerfilNotifier(ref),
);

// ─── Cerrar sesión ────────────────────────────────────────────────────────────

Future<void> cerrarSesion(WidgetRef ref) async {
  await Supabase.instance.client.auth.signOut();
  ref.invalidate(currentUserProvider);
}

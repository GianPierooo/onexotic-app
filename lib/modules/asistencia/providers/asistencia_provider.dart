import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum EstadoAsistencia { presente, ausente, pendiente }

enum EstadoSemana { todos, parcial, ausencias }

// ─── Modelos de pantalla ──────────────────────────────────────────────────────

class MiembroConEstado {
  final String id;
  final String nombre;
  final String rol;
  final EstadoAsistencia estado;
  final DateTime? horaEntrada;

  const MiembroConEstado({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.estado,
    this.horaEntrada,
  });
}

class ReunionHoyData {
  final List<MiembroConEstado> miembros;
  final bool yaMarque;

  int get presentes =>
      miembros.where((m) => m.estado == EstadoAsistencia.presente).length;
  int get total => miembros.length;

  const ReunionHoyData({required this.miembros, required this.yaMarque});
}

class DiaSemana {
  final DateTime fecha;
  final EstadoSemana? estado; // null = sin registros ese día

  const DiaSemana({required this.fecha, this.estado});
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── Provider: reunión de hoy ─────────────────────────────────────────────────

final reunionHoyProvider = FutureProvider<ReunionHoyData>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  final today = _fmtDate(DateTime.now());

  try {
    final usuarios = await client
        .from('users')
        .select('id, nombre, rol')
        .eq('activo', true)
        .order('nombre');

    final asistencia = await client
        .from('asistencia')
        .select('user_id, presente, hora_entrada')
        .eq('fecha', today)
        .eq('reunion_tipo', 'diaria');

    final asistenciaMap = <String, Map<String, dynamic>>{
      for (final a in asistencia) a['user_id'] as String: a,
    };

    final miembros = (usuarios as List).map((u) {
      final uid = u['id'] as String;
      final reg = asistenciaMap[uid];
      EstadoAsistencia estado;
      if (reg == null) {
        estado = EstadoAsistencia.pendiente;
      } else if (reg['presente'] == true) {
        estado = EstadoAsistencia.presente;
      } else {
        estado = EstadoAsistencia.ausente;
      }
      return MiembroConEstado(
        id: uid,
        nombre: u['nombre'] as String,
        rol: u['rol'] as String,
        estado: estado,
        horaEntrada: reg?['hora_entrada'] != null
            ? DateTime.tryParse(reg!['hora_entrada'] as String)
            : null,
      );
    }).toList();

    final yaMarque = userId != null &&
        asistenciaMap[userId]?['presente'] == true;

    return ReunionHoyData(miembros: miembros, yaMarque: yaMarque);
  } catch (e, st) {
    if (kDebugMode) print('[reunionHoy] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Provider: semana actual ──────────────────────────────────────────────────

final semanaAsistenciaProvider =
    FutureProvider<List<DiaSemana>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final dias = List.generate(7, (i) => monday.add(Duration(days: i)));

  try {
    final totalUsuarios =
        (await client.from('users').select('id').eq('activo', true)).length;

    final registros = await client
        .from('asistencia')
        .select('fecha, presente')
        .gte('fecha', _fmtDate(dias.first))
        .lte('fecha', _fmtDate(dias.last))
        .eq('reunion_tipo', 'diaria');

    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final r in registros as List) {
      final fecha = r['fecha'] as String;
      byDate.putIfAbsent(fecha, () => []).add(r);
    }

    return dias.map((dia) {
      final recs = byDate[_fmtDate(dia)] ?? [];
      if (recs.isEmpty) return DiaSemana(fecha: dia);
      final presentes = recs.where((r) => r['presente'] == true).length;
      EstadoSemana estado;
      if (presentes >= totalUsuarios) {
        estado = EstadoSemana.todos;
      } else if (presentes > 0) {
        estado = EstadoSemana.parcial;
      } else {
        estado = EstadoSemana.ausencias;
      }
      return DiaSemana(fecha: dia, estado: estado);
    }).toList();
  } catch (e) {
    if (kDebugMode) print('[semana] ERROR: $e');
    return List.generate(
        7, (i) => DiaSemana(fecha: monday.add(Duration(days: i))));
  }
});

// ─── Provider: historial ──────────────────────────────────────────────────────

final historialProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  try {
    final data = await client
        .from('asistencia')
        .select('fecha, presente, reunion_tipo')
        .eq('reunion_tipo', 'diaria')
        .order('fecha', ascending: false)
        .limit(50);

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in data as List) {
      final fecha = r['fecha'] as String;
      grouped.putIfAbsent(fecha, () => []).add(r);
    }

    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sorted.take(3).map((fecha) {
      final recs = grouped[fecha]!;
      final presentes = recs.where((r) => r['presente'] == true).length;
      return {
        'fecha': fecha,
        'tipo': recs.first['reunion_tipo'],
        'presentes': presentes,
        'total': recs.length,
      };
    }).toList();
  } catch (e) {
    if (kDebugMode) print('[historial] ERROR: $e');
    return [];
  }
});

// ─── Notifier: marcar asistencia ──────────────────────────────────────────────

class MarcarAsistenciaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MarcarAsistenciaNotifier(this._ref) : super(const AsyncValue.data(null));

  /// [reunionId] es el id de la reunión a la que pertenece el registro.
  Future<void> marcar({required String reunionId}) async {
    state = const AsyncValue.loading();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = AsyncValue.error('Sin sesión activa', StackTrace.current);
      return;
    }
    try {
      // Actualizar el registro pre-creado (presente=false → true)
      await Supabase.instance.client
          .from('asistencia')
          .update({
            'presente': true,
            'hora_entrada': DateTime.now().toIso8601String(),
          })
          .eq('reunion_id', reunionId)
          .eq('user_id', userId);
      _ref.invalidate(reunionHoyProvider);
      _ref.invalidate(semanaAsistenciaProvider);
      _ref.invalidate(historialProvider);
      state = const AsyncValue.data(null);
    } on PostgrestException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}

final marcarAsistenciaProvider =
    StateNotifierProvider<MarcarAsistenciaNotifier, AsyncValue<void>>(
  (ref) => MarcarAsistenciaNotifier(ref),
);

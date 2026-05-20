// SQL requerido en Supabase:
//
// CREATE TABLE IF NOT EXISTS eventos_calendario (
//   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
//   tipo text NOT NULL,
//   titulo text NOT NULL,
//   fecha date NOT NULL,
//   hora time,
//   lugar text,
//   descripcion text,
//   color text DEFAULT '#FF4500',
//   creado_por uuid REFERENCES users(id),
//   created_at timestamptz DEFAULT now()
// );
// ALTER TABLE eventos_calendario ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "auth_all_eventos" ON eventos_calendario
//   FOR ALL TO authenticated USING (true) WITH CHECK (true);

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';

// ─── Modelo ───────────────────────────────────────────────────────────────────

class EventoCalendario {
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final TimeOfDay? hora;
  final String tipo; // 'drop'|'reunion'|'tarea'|'disenio'|'evento'
  final Color color;
  final String? colorHex;
  final String? lugar;
  final bool esEditable; // true solo para eventos_calendario
  final String? tipoDb;  // nombre del tipo tal como está en DB ('Reunión de equipo', etc.)

  const EventoCalendario({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    this.hora,
    required this.tipo,
    required this.color,
    this.colorHex,
    this.lugar,
    this.esEditable = false,
    this.tipoDb,
  });

  static Color colorForTipo(String tipo) => switch (tipo) {
        'drop'    => const Color(0xFFFF4500),
        'reunion' => const Color(0xFF3B82F6),
        'tarea'   => const Color(0xFFF59E0B),
        'disenio' => const Color(0xFF8B5CF6),
        'evento'  => const Color(0xFFA78BFA),
        _         => const Color(0xFF888888),
      };

  String get moduloBadge => switch (tipo) {
        'drop'    => 'Drop',
        'reunion' => 'Reunión',
        'tarea'   => 'Tarea',
        'disenio' => 'Diseño',
        _         => '',
      };

  String get rutaModulo => switch (tipo) {
        'drop'    => '/inventario',
        'reunion' => '/asistencia',
        'tarea'   => '/tareas',
        'disenio' => '/disenios',
        _         => '',
      };
}

// ─── Estado del calendario ────────────────────────────────────────────────────

final mesSeleccionadoProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

final diaSeleccionadoProvider = StateProvider<DateTime?>((_) => null);

final vistaCalendarioProvider = StateProvider<String>((_) => 'mes');

final semanaSeleccionadaProvider = StateProvider<DateTime>((ref) {
  final hoy = DateTime.now();
  return hoy.subtract(Duration(days: hoy.weekday - 1));
});

// ─── Eventos del mes (todas las fuentes fusionadas) ───────────────────────────

final calendarioEventosProvider =
    FutureProvider<Map<String, List<EventoCalendario>>>((ref) async {
  final mes = ref.watch(mesSeleccionadoProvider);
  final client = Supabase.instance.client;

  final primerDia = DateTime(mes.year, mes.month, 1);
  final ultimoDia = DateTime(mes.year, mes.month + 1, 0);
  final desde = dateStr(primerDia);
  final hasta = dateStr(ultimoDia);

  final Map<String, List<EventoCalendario>> mapa = {};

  void agregar(EventoCalendario e) {
    final k = dateStr(DateTime(e.fecha.year, e.fecha.month, e.fecha.day));
    mapa.putIfAbsent(k, () => []).add(e);
  }

  // 1. eventos_calendario (editables)
  try {
    final rows = await client
        .from('eventos_calendario')
        .select()
        .gte('fecha', desde)
        .lte('fecha', hasta)
        .order('fecha');
    for (final r in rows as List) {
      final fecha = DateTime.tryParse(r['fecha'] as String? ?? '');
      if (fecha == null) continue;
      final colorHex = r['color'] as String? ?? '#FF4500';
      agregar(EventoCalendario(
        id: r['id'] as String,
        titulo: r['titulo'] as String? ?? '',
        descripcion: r['descripcion'] as String?,
        fecha: fecha,
        hora: _parseHora(r['hora'] as String?),
        tipo: 'evento',
        color: hexToColor(colorHex),
        colorHex: colorHex,
        lugar: r['lugar'] as String?,
        esEditable: true,
        tipoDb: r['tipo'] as String?,
      ));
    }
  } catch (e) {
    if (kDebugMode) print('[calendario] eventos: $e');
  }

  // 2. Drops → fecha_lanzamiento
  try {
    final rows = await client
        .from('drops')
        .select('id, nombre, fecha_lanzamiento')
        .gte('fecha_lanzamiento', desde)
        .lte('fecha_lanzamiento', hasta);
    for (final d in rows as List) {
      final fecha = DateTime.tryParse(d['fecha_lanzamiento'] as String? ?? '');
      if (fecha == null) continue;
      agregar(EventoCalendario(
        id: d['id'] as String,
        titulo: 'Lanzamiento: ${d['nombre']}',
        descripcion: 'Lanzamiento de drop',
        fecha: fecha,
        tipo: 'drop',
        color: EventoCalendario.colorForTipo('drop'),
      ));
    }
  } catch (e) {
    if (kDebugMode) print('[calendario] drops: $e');
  }

  // 3. Reuniones
  try {
    final rows = await client
        .from('asistencia')
        .select('id, fecha, reunion_tipo')
        .gte('fecha', desde)
        .lte('fecha', hasta)
        .eq('presente', true);
    final vistas = <String>{};
    for (final a in rows as List) {
      final fechaStr = a['fecha'] as String? ?? '';
      if (fechaStr.isEmpty || vistas.contains(fechaStr)) continue;
      vistas.add(fechaStr);
      final fecha = DateTime.tryParse(fechaStr);
      if (fecha == null) continue;
      agregar(EventoCalendario(
        id: a['id'] as String,
        titulo: _labelReunion(a['reunion_tipo'] as String? ?? 'diaria'),
        descripcion: '9:00 AM · Reunión de equipo',
        fecha: fecha,
        hora: const TimeOfDay(hour: 9, minute: 0),
        tipo: 'reunion',
        color: EventoCalendario.colorForTipo('reunion'),
      ));
    }
  } catch (e) {
    if (kDebugMode) print('[calendario] reuniones: $e');
  }

  // 4. Tareas → fecha_limite (no completadas)
  try {
    final rows = await client
        .from('tareas')
        .select('id, titulo, fecha_limite')
        .gte('fecha_limite', desde)
        .lte('fecha_limite', hasta)
        .eq('completado', false);
    for (final t in rows as List) {
      final fecha = DateTime.tryParse(t['fecha_limite'] as String? ?? '');
      if (fecha == null) continue;
      agregar(EventoCalendario(
        id: t['id'] as String,
        titulo: t['titulo'] as String? ?? 'Tarea',
        descripcion: 'Fecha límite de tarea',
        fecha: fecha,
        tipo: 'tarea',
        color: EventoCalendario.colorForTipo('tarea'),
      ));
    }
  } catch (e) {
    if (kDebugMode) print('[calendario] tareas: $e');
  }

  // 5. Diseños → fecha_limite
  try {
    final rows = await client
        .from('disenios')
        .select('id, titulo, fecha_limite')
        .gte('fecha_limite', desde)
        .lte('fecha_limite', hasta);
    for (final d in rows as List) {
      final fecha = DateTime.tryParse(d['fecha_limite'] as String? ?? '');
      if (fecha == null) continue;
      agregar(EventoCalendario(
        id: d['id'] as String,
        titulo: 'Entrega diseño: ${d['titulo']}',
        descripcion: 'Fecha límite de diseño',
        fecha: fecha,
        tipo: 'disenio',
        color: EventoCalendario.colorForTipo('disenio'),
      ));
    }
  } catch (e) {
    if (kDebugMode) print('[calendario] diseños: $e');
  }

  return mapa;
});

// ─── Crear evento ─────────────────────────────────────────────────────────────

class CrearEventoNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CrearEventoNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> crear({
    required String tipo,
    required String titulo,
    required DateTime fecha,
    TimeOfDay? hora,
    String? lugar,
    String? descripcion,
    required String colorHex,
  }) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    try {
      await client.from('eventos_calendario').insert({
        'tipo': tipo,
        'titulo': titulo,
        'fecha': dateStr(fecha),
        if (hora != null)
          'hora': '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00',
        if (lugar != null && lugar.trim().isNotEmpty) 'lugar': lugar.trim(),
        if (descripcion != null && descripcion.trim().isNotEmpty)
          'descripcion': descripcion.trim(),
        'color': colorHex,
        if (userId != null) 'creado_por': userId,
      });

      if (tipo == 'Reunión de equipo') {
        await _notificarReunion(titulo, fecha, hora);
      }

      _ref.invalidate(calendarioEventosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[crear evento] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> _notificarReunion(
      String titulo, DateTime fecha, TimeOfDay? hora) async {
    try {
      final client = Supabase.instance.client;
      final usuarios =
          await client.from('users').select('id').eq('activo', true);
      final fechaStr =
          '${fecha.day}/${fecha.month}/${fecha.year}';
      final horaStr = hora != null
          ? ' a las ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
          : '';
      await pushNotifMultiple(
        userIds: (usuarios as List).map((u) => u['id'] as String).toList(),
        titulo: 'Nueva reunión: $titulo',
        mensaje: 'Nueva reunión: $titulo el $fechaStr$horaStr',
        tipo: 'asistencia',
      );
    } catch (_) {}
  }
}

final crearEventoProvider =
    StateNotifierProvider<CrearEventoNotifier, AsyncValue<void>>(
  (ref) => CrearEventoNotifier(ref),
);

// ─── Editar evento ────────────────────────────────────────────────────────────

class EditarEventoNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EditarEventoNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> editar({
    required String eventoId,
    required String tipo,
    required String titulo,
    required DateTime fecha,
    TimeOfDay? hora,
    String? lugar,
    String? descripcion,
    required String colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('eventos_calendario')
          .update({
        'tipo': tipo,
        'titulo': titulo,
        'fecha': dateStr(fecha),
        'hora': hora != null
            ? '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00'
            : null,
        'lugar': lugar?.trim().isNotEmpty == true ? lugar!.trim() : null,
        'descripcion':
            descripcion?.trim().isNotEmpty == true ? descripcion!.trim() : null,
        'color': colorHex,
      }).eq('id', eventoId);
      _ref.invalidate(calendarioEventosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[editar evento] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final editarEventoProvider =
    StateNotifierProvider<EditarEventoNotifier, AsyncValue<void>>(
  (ref) => EditarEventoNotifier(ref),
);

// ─── Eliminar evento ──────────────────────────────────────────────────────────

class EliminarEventoNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EliminarEventoNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> eliminar(String eventoId) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('eventos_calendario')
          .delete()
          .eq('id', eventoId);
      _ref.invalidate(calendarioEventosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[eliminar evento] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final eliminarEventoProvider =
    StateNotifierProvider<EliminarEventoNotifier, AsyncValue<void>>(
  (ref) => EliminarEventoNotifier(ref),
);

// ─── Helpers ─────────────────────────────────────────────────────────────────

String dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _labelReunion(String tipo) => switch (tipo) {
      'diaria'         => 'Reunión diaria',
      'semanal'        => 'Reunión semanal',
      'extraordinaria' => 'Reunión extraordinaria',
      _                => 'Reunión',
    };

TimeOfDay? _parseHora(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length < 2) return null;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

Color hexToColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFFFF4500);
  }
}

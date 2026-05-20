import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';
import 'asistencia_provider.dart';

// --- Modelo reunión -----------------------------------------------------------

class Reunion {
  final String id;
  final String tipo;
  final DateTime fecha;
  final String hora; // 'HH:mm'
  final String lugar;
  final String? descripcion;
  final List<String> temas;
  final String recurrencia; // 'ninguna' | 'diaria' | 'semanal' | 'laboral' | 'personalizado'
  final String? recurrenciaGrupoId;

  const Reunion({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.lugar,
    this.descripcion,
    this.temas = const [],
    this.recurrencia = 'ninguna',
    this.recurrenciaGrupoId,
  });

  bool get esRecurrente => recurrencia != 'ninguna';

  String get recurrenciaLabel => switch (recurrencia) {
        'diaria'        => 'Diaria',
        'semanal'       => 'Semanal',
        'laboral'       => 'Lun·Vie',
        'personalizado' => 'Personalizada',
        _               => '',
      };

  factory Reunion.fromJson(Map<String, dynamic> json) => Reunion(
        id: json['id'] as String,
        tipo: json['tipo'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        hora: (json['hora'] as String).substring(0, 5), // 'HH:mm:ss' ? 'HH:mm'
        lugar: json['lugar'] as String? ?? 'Showroom',
        descripcion: json['descripcion'] as String?,
        temas: (json['temas'] as List?)?.cast<String>() ?? [],
        recurrencia: json['recurrencia'] as String? ?? 'ninguna',
        recurrenciaGrupoId: json['recurrencia_grupo_id'] as String?,
      );
}

// --- Provider: reunión de hoy -------------------------------------------------

final reunionDeHoyProvider = FutureProvider<Reunion?>((ref) async {
  final today = _fmtDate(DateTime.now());
  try {
    final data = await Supabase.instance.client
        .from('reuniones')
        .select('*')
        .eq('fecha', today)
        .order('created_at', ascending: false)
        .limit(1);
    if ((data as List).isEmpty) return null;
    return Reunion.fromJson(data.first);
  } catch (e) {
    if (kDebugMode) print('[reunionDeHoy] ERROR: $e');
    return null;
  }
});

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// --- Notifier: crear reunión --------------------------------------------------

class CrearReunionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CrearReunionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> crear({
    required String tipo,
    required DateTime fecha,
    required String hora, // 'HH:mm'
    required String lugar,
    String? descripcion,
    List<String> temas = const [],
    required List<String> participantesIds,
    String recurrencia = 'ninguna',
    DateTime? recurrenciaFin,
    List<int> recurrenciaDias = const [], // 1=Lun,2=Mar,...,7=Dom (ISO weekday)
  }) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      state = AsyncValue.error('Sin sesión', StackTrace.current);
      return false;
    }
    try {
      // Genera todas las fechas a crear según el patrón de recurrencia.
      final fechas = _generarFechas(
        inicio: fecha,
        fin: recurrenciaFin ?? fecha.add(const Duration(days: 30)),
        recurrencia: recurrencia,
        diasPersonalizados: recurrenciaDias,
      );

      // ID de grupo compartido por todas las ocurrencias de la serie.
      final grupoId = recurrencia != 'ninguna'
          ? _generarUuid()
          : null;

      for (final f in fechas) {
        // 1. Crear la reunión
        final reunionData = await client.from('reuniones').insert({
          'tipo': tipo,
          'fecha': _fmtDate(f),
          'hora': '$hora:00',
          'lugar': lugar,
          if (descripcion != null && descripcion.trim().isNotEmpty)
            'descripcion': descripcion.trim(),
          if (temas.isNotEmpty) 'temas': temas,
          'creado_por': userId,
          'recurrencia': recurrencia,
          if (grupoId != null) 'recurrencia_grupo_id': grupoId,
          if (recurrenciaDias.isNotEmpty) 'recurrencia_dias': recurrenciaDias,
          if (recurrenciaFin != null)
            'recurrencia_fin': _fmtDate(recurrenciaFin),
        }).select('id').single();

        final reunionId = reunionData['id'] as String;

        // 2. Crear registros asistencia para cada participante
        final asistenciaRows = participantesIds
            .map((uid) => {
                  'user_id': uid,
                  'fecha': _fmtDate(f),
                  'presente': false,
                  'reunion_tipo': tipo,
                  'reunion_id': reunionId,
                })
            .toList();
        await client.from('asistencia').insert(asistenciaRows);
      }

      // 3. Notificación única (solo para la primera fecha)
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      final recLabel = recurrencia != 'ninguna' ? ' · ${_labelRecurrencia(recurrencia)}' : '';
      final notifs = participantesIds
          .where((uid) => uid != userId)
          .map((uid) => {
                'user_id': uid,
                'titulo': 'Nueva reunión programada$recLabel',
                'mensaje':
                    'Reunión ${_labelTipo(tipo)} el $fechaStr a $hora en $lugar',
                'tipo': 'asistencia',
              })
          .toList();
      // Inserta notificaciones + envía push a cada participante
      if (notifs.isNotEmpty) {
        await pushNotifMultiple(
          userIds: notifs.map((n) => n['user_id'] as String).toList(),
          titulo: notifs.first['titulo'] as String,
          mensaje: notifs.first['mensaje'] as String,
          tipo: 'asistencia',
        );
      }

      _ref.invalidate(reunionDeHoyProvider);
      _ref.invalidate(reunionHoyProvider);
      _ref.invalidate(semanaAsistenciaProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[crearReunion] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Genera la lista de fechas para una serie recurrente.
  List<DateTime> _generarFechas({
    required DateTime inicio,
    required DateTime fin,
    required String recurrencia,
    List<int> diasPersonalizados = const [],
  }) {
    if (recurrencia == 'ninguna') return [inicio];
    final fechas = <DateTime>[];
    var cursor = inicio;
    while (!cursor.isAfter(fin)) {
      final dia = cursor.weekday; // 1=Lun · 7=Dom
      final incluir = switch (recurrencia) {
        'diaria'        => true,
        'semanal'       => dia == inicio.weekday,
        'laboral'       => dia >= 1 && dia <= 5,
        'personalizado' => diasPersonalizados.contains(dia),
        _               => false,
      };
      if (incluir) fechas.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return fechas;
  }

  String _generarUuid() {
    // UUID v4 simple sin dependencias externas.
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = now.toString().padLeft(16, '0');
    return '${r.substring(0,8)}-${r.substring(8,12)}-4${r.substring(12,15)}-8${r.substring(15,18)}-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _labelRecurrencia(String r) => switch (r) {
        'diaria'        => 'Diaria',
        'semanal'       => 'Semanal',
        'laboral'       => 'Lun·Vie',
        'personalizado' => 'Personalizada',
        _               => '',
      };

  String _labelTipo(String t) => switch (t) {
        'diaria' => 'diaria',
        'semanal' => 'semanal',
        'extraordinaria' => 'extraordinaria',
        _ => t,
      };
}

final crearReunionProvider =
    StateNotifierProvider<CrearReunionNotifier, AsyncValue<void>>(
  (ref) => CrearReunionNotifier(ref),
);

// --- Provider: asistencia de una reunión específica (por reunion_id) ----------

final asistenciaReunionProvider =
    FutureProvider.family<ReunionHoyData, String>((ref, reunionId) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  try {
    // Traer todos los registros de asistencia de esta reunión
    final asistencia = await client
        .from('asistencia')
        .select('user_id, presente, hora_entrada, users(nombre, rol)')
        .eq('reunion_id', reunionId);

    final miembros = (asistencia as List).map((a) {
      final uid = a['user_id'] as String;
      final userMap = a['users'] as Map<String, dynamic>?;
      EstadoAsistencia estado;
      if (a['presente'] == true) {
        estado = EstadoAsistencia.presente;
      } else {
        estado = EstadoAsistencia.ausente;
      }
      return MiembroConEstado(
        id: uid,
        nombre: userMap?['nombre'] as String? ?? uid,
        rol: userMap?['rol'] as String? ?? '',
        estado: estado,
        horaEntrada: a['hora_entrada'] != null
            ? DateTime.tryParse(a['hora_entrada'] as String)
            : null,
      );
    }).toList();

    final yaMarque = userId != null &&
        miembros.any(
            (m) => m.id == userId && m.estado == EstadoAsistencia.presente);

    return ReunionHoyData(miembros: miembros, yaMarque: yaMarque);
  } catch (e) {
    if (kDebugMode) print('[asistenciaReunion] ERROR: $e');
    rethrow;
  }
});

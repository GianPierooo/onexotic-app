// Provider del Modo Asistente — IA con tool calling y soporte de imágenes.
//
// Flujo:
//  1. CEO envía mensaje (con o sin imágenes adjuntas).
//  2. Si hay imágenes, se suben a Supabase Storage (bucket 'referencias',
//     path 'chat/{userId}/{ts}_{i}.{ext}') ANTES de invocar la edge function.
//  3. La edge function recibe imagenes_urls y arma contenido multimodal
//     para gpt-4o-mini (vision).
//  4. Si devuelve tool_call, las acciones SIEMPRE pasan por la burbuja de
//     confirmación con resumen — doble check después del resumen textual
//     que ya dio la IA.
//  5. Al ejecutar crear_brief, se usan las imagenesUrls acumuladas en el
//     historial del usuario como referencias_urls del brief.


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';
import '../../calendario/providers/calendario_provider.dart';
import '../../disenios/providers/briefs_provider.dart';
import '../../disenios/providers/disenios_provider.dart';
import '../../inventario/providers/drops_provider.dart';
import '../../tareas/providers/tareas_provider.dart';
import 'ai_provider.dart' show MensajeChat;

// ─── Imagen adjunta (antes de subir) ───────────────────────────────────────────

class ImagenAdjunta {
  final Uint8List bytes;
  final String ext; // jpg, png, webp...
  final String nombre;
  const ImagenAdjunta({
    required this.bytes,
    required this.ext,
    required this.nombre,
  });
}

// ─── Confirmación pendiente ────────────────────────────────────────────────────

class ConfirmacionPendiente {
  final String mensajeId;
  final String tool;
  final Map<String, dynamic> args;
  final String resumen;
  // URLs de imágenes que vienen del turno actual (devueltas por la edge).
  final List<String> imagenesUrlsTurno;

  const ConfirmacionPendiente({
    required this.mensajeId,
    required this.tool,
    required this.args,
    required this.resumen,
    this.imagenesUrlsTurno = const [],
  });
}

// ─── Estado ───────────────────────────────────────────────────────────────────

class AiAsistenteState {
  final List<MensajeChat> mensajes;
  final bool isTyping;
  final bool isEjecutando;
  final bool isSubiendo; // subiendo imágenes adjuntas
  final ConfirmacionPendiente? pendiente;
  final String? error;

  const AiAsistenteState({
    this.mensajes = const [],
    this.isTyping = false,
    this.isEjecutando = false,
    this.isSubiendo = false,
    this.pendiente,
    this.error,
  });

  AiAsistenteState copyWith({
    List<MensajeChat>? mensajes,
    bool? isTyping,
    bool? isEjecutando,
    bool? isSubiendo,
    ConfirmacionPendiente? pendiente,
    bool clearPendiente = false,
    String? error,
    bool clearError = false,
  }) {
    return AiAsistenteState(
      mensajes: mensajes ?? this.mensajes,
      isTyping: isTyping ?? this.isTyping,
      isEjecutando: isEjecutando ?? this.isEjecutando,
      isSubiendo: isSubiendo ?? this.isSubiendo,
      pendiente: clearPendiente ? null : (pendiente ?? this.pendiente),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────────

class AiAsistenteNotifier extends StateNotifier<AiAsistenteState> {
  final Ref _ref;
  AiAsistenteNotifier(this._ref) : super(const AiAsistenteState());

  String _nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> enviar(
    String texto, {
    List<ImagenAdjunta> imagenes = const [],
  }) async {
    final t = texto.trim();
    if (t.isEmpty && imagenes.isEmpty) return;

    // 1. Subir imágenes a Storage primero (si las hay)
    state = state.copyWith(
      clearError: true,
      clearPendiente: true,
      isSubiendo: imagenes.isNotEmpty,
    );

    List<String> imagenesUrls = const [];
    if (imagenes.isNotEmpty) {
      try {
        imagenesUrls = await _subirImagenes(imagenes);
      } catch (e) {
        if (kDebugMode) print('[ai-asistente] subir imágenes ERROR: $e');
        state = state.copyWith(
          isSubiendo: false,
          error: 'No se pudieron subir las imágenes.',
        );
        return;
      }
      state = state.copyWith(isSubiendo: false);
    }

    // 2. Armar mensaje del usuario en el historial local (con URLs adjuntas)
    final mensajeBody = t.isEmpty ? '(imagen adjunta)' : t;
    final msgUser = MensajeChat(
      id: _nuevoId(),
      texto: mensajeBody,
      esUsuario: true,
      timestamp: DateTime.now(),
      imagenesUrls: imagenesUrls,
    );

    // 3. Historial reciente para que la IA mantenga contexto.
    //    No le pasamos las imágenes del historial — solo las del turno actual,
    //    para no inflar tokens (cada imagen en el contexto cuesta caro).
    final prev = state.mensajes.length > 6
        ? state.mensajes.sublist(state.mensajes.length - 6)
        : List<MensajeChat>.from(state.mensajes);
    final historial = prev
        .map((m) => {
              'role': m.esUsuario ? 'user' : 'assistant',
              'content': m.texto,
            })
        .toList();

    state = state.copyWith(
      mensajes: [...state.mensajes, msgUser],
      isTyping: true,
    );

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-asistente',
        body: {
          'mensaje': mensajeBody,
          'historial': historial,
          'imagenes_urls': imagenesUrls,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw Exception('Respuesta inválida del asistente');
      }

      final tipo = data['tipo'] as String?;

      if (tipo == 'tool_call') {
        await _procesarToolCall(data);
        return;
      }

      final respuesta =
          data['respuesta'] as String? ?? 'No tengo esa información.';
      _agregarMensajeIA(respuesta);
      state = state.copyWith(isTyping: false);
    } catch (e) {
      if (kDebugMode) print('[ai-asistente] ERROR enviar: $e');
      state = state.copyWith(
        isTyping: false,
        error: 'No se pudo conectar con el asistente.',
      );
    }
  }

  // ── Tool call handling ────────────────────────────────────────────────────

  Future<void> _procesarToolCall(Map data) async {
    final tool = data['tool'] as String? ?? '';
    final args = Map<String, dynamic>.from(data['args'] as Map? ?? {});
    final requiere = data['requiere_confirmacion'] as bool? ?? true;
    final resumen = data['resumen'] as String? ?? '';
    final imagenesTurno = (data['imagenes_urls'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    if (requiere) {
      final mensajeId = _nuevoId();
      final pendiente = ConfirmacionPendiente(
        mensajeId: mensajeId,
        tool: tool,
        args: args,
        resumen: resumen,
        imagenesUrlsTurno: imagenesTurno,
      );
      final placeholder = MensajeChat(
        id: mensajeId,
        texto: '__pendiente_confirmacion__',
        esUsuario: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        mensajes: [...state.mensajes, placeholder],
        isTyping: false,
        pendiente: pendiente,
      );
      return;
    }

    // Por ahora todas requieren confirmación, pero dejamos esto por si cambia.
    state = state.copyWith(isTyping: false, isEjecutando: true);
    final res = await _ejecutarTool(tool, args, imagenesTurno);
    state = state.copyWith(isEjecutando: false);
    _agregarMensajeIA(
        res.ok ? res.mensaje : 'No pude completar la acción: ${res.mensaje}');
  }

  Future<void> confirmar() async {
    final p = state.pendiente;
    if (p == null) return;

    final sinPlaceholder =
        state.mensajes.where((m) => m.id != p.mensajeId).toList();
    state = state.copyWith(
      mensajes: sinPlaceholder,
      clearPendiente: true,
      isEjecutando: true,
    );

    final res = await _ejecutarTool(p.tool, p.args, p.imagenesUrlsTurno);
    state = state.copyWith(isEjecutando: false);
    _agregarMensajeIA(
        res.ok ? res.mensaje : 'No pude completar la acción: ${res.mensaje}');
  }

  void cancelar() {
    final p = state.pendiente;
    if (p == null) return;
    final sinPlaceholder =
        state.mensajes.where((m) => m.id != p.mensajeId).toList();
    state = state.copyWith(
      mensajes: sinPlaceholder,
      clearPendiente: true,
    );
    _agregarMensajeIA('Cancelado. ¿Qué quieres ajustar?');
  }

  void limpiar() {
    state = const AiAsistenteState();
  }

  // ── Storage helper ────────────────────────────────────────────────────────

  Future<List<String>> _subirImagenes(List<ImagenAdjunta> imagenes) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];
    for (int i = 0; i < imagenes.length; i++) {
      final img = imagenes[i];
      // Bucket 'referencias' ya existe (lo usa briefs). Path bajo /chat/.
      final path = 'chat/$userId/${ts}_$i.${img.ext}';
      await Supabase.instance.client.storage.from('referencias').uploadBinary(
            path,
            img.bytes,
            fileOptions: FileOptions(
              contentType: 'image/${img.ext == "jpg" ? "jpeg" : img.ext}',
              upsert: false,
            ),
          );
      urls.add(Supabase.instance.client.storage
          .from('referencias')
          .getPublicUrl(path));
    }
    return urls;
  }

  // ── Ejecutores de tools ───────────────────────────────────────────────────

  Future<_ToolResult> _ejecutarTool(
    String tool,
    Map<String, dynamic> args,
    List<String> imagenesTurno,
  ) async {
    try {
      switch (tool) {
        case 'crear_tarea':
          return await _toolCrearTarea(args);
        case 'crear_evento':
          return await _toolCrearEvento(args);
        case 'crear_brief':
          return await _toolCrearBrief(args, imagenesTurno);
        case 'aprobar_disenio':
          return await _toolAprobarDisenio(args);
        case 'rechazar_disenio':
          return await _toolRechazarDisenio(args);
        case 'crear_drop':
          return await _toolCrearDrop(args);
        case 'crear_bono':
          return await _toolCrearBono(args);
        case 'anuncio_equipo':
          return await _toolAnuncioEquipo(args);
        default:
          return _ToolResult.err('Acción no soportada ($tool).');
      }
    } catch (e) {
      if (kDebugMode) print('[ai-asistente] tool $tool ERROR: $e');
      return _ToolResult.err(e.toString());
    }
  }

  Future<_ToolResult> _toolCrearTarea(Map<String, dynamic> args) async {
    final titulo = args['titulo'] as String?;
    final area = args['area'] as String?;
    final prioridad = args['prioridad'] as String?;
    if (titulo == null || titulo.trim().isEmpty) {
      return const _ToolResult.err('falta título');
    }
    if (area == null || area.isEmpty) {
      return const _ToolResult.err('falta área');
    }
    if (prioridad == null || prioridad.isEmpty) {
      return const _ToolResult.err('falta prioridad');
    }

    final fechaStr = args['fecha_limite'] as String?;
    DateTime? fecha;
    if (fechaStr != null && fechaStr.isNotEmpty) {
      fecha = DateTime.tryParse(fechaStr);
    }

    final res = await _ref.read(crearTareaProvider.notifier).crear(
          titulo: titulo,
          area: area,
          prioridad: prioridad,
          descripcion: args['descripcion'] as String?,
          asignadoA: args['asignado_a_id'] as String?,
          fechaLimite: fecha,
        );
    if (!res.ok) return _ToolResult.err(res.error ?? 'error desconocido');

    String? nombreAsignado;
    final asignadoId = args['asignado_a_id'] as String?;
    if (asignadoId != null && asignadoId.isNotEmpty) {
      nombreAsignado = await _buscarNombreUsuario(asignadoId);
    }

    final partes = <String>['Listo, creé la tarea «$titulo»'];
    if (nombreAsignado != null) partes.add('asignada a $nombreAsignado');
    if (fecha != null) partes.add('con fecha límite ${_fechaLegible(fecha)}');
    return _ToolResult.ok('${partes.join(' ')}.');
  }

  Future<_ToolResult> _toolCrearEvento(Map<String, dynamic> args) async {
    final tipo = args['tipo'] as String? ?? 'evento_especial';
    final titulo = args['titulo'] as String?;
    final fechaStr = args['fecha'] as String?;
    if (titulo == null || titulo.trim().isEmpty) {
      return const _ToolResult.err('falta título');
    }
    if (fechaStr == null || fechaStr.isEmpty) {
      return const _ToolResult.err('falta fecha');
    }
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) {
      return _ToolResult.err('fecha inválida ($fechaStr)');
    }

    TimeOfDay? hora;
    final horaStr = args['hora'] as String?;
    if (horaStr != null && horaStr.contains(':')) {
      final parts = horaStr.split(':');
      hora = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    final ok = await _ref.read(crearEventoProvider.notifier).crear(
          tipo: _mapearTipoEvento(tipo),
          titulo: titulo,
          fecha: fecha,
          hora: hora,
          lugar: args['lugar'] as String?,
          descripcion: args['descripcion'] as String?,
          colorHex: _colorPorTipo(tipo),
        );
    if (!ok) return const _ToolResult.err('no se pudo crear el evento');

    final horaTxt = hora != null
        ? ' a las ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
        : '';
    return _ToolResult.ok(
        'Listo, agregué «$titulo» al calendario para ${_fechaLegible(fecha)}$horaTxt.');
  }

  Future<_ToolResult> _toolCrearBrief(
    Map<String, dynamic> args,
    List<String> imagenesTurno,
  ) async {
    final titulo = args['titulo'] as String?;
    final dropId = args['drop_id'] as String?;
    final descripcion = args['descripcion'] as String?;
    final fechaStr = args['fecha_limite'] as String?;
    if (titulo == null || titulo.trim().isEmpty) {
      return const _ToolResult.err('falta título');
    }
    if (dropId == null || dropId.isEmpty) {
      return const _ToolResult.err('falta drop');
    }
    if (descripcion == null || descripcion.trim().isEmpty) {
      return const _ToolResult.err('falta descripción');
    }
    if (fechaStr == null || fechaStr.isEmpty) {
      return const _ToolResult.err('falta fecha límite');
    }
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return const _ToolResult.err('fecha inválida');

    final colores = (args['colores'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    // Reunir referencias: las del turno actual + todas las acumuladas en
    // mensajes anteriores del usuario. Permite que el CEO adjunte imágenes
    // en un turno y la IA decida crear el brief en otro turno posterior.
    final urlsHistorial = state.mensajes
        .where((m) => m.esUsuario)
        .expand((m) => m.imagenesUrls)
        .toList();
    final usarImgs = args['usar_imagenes_adjuntas'] as bool? ?? false;
    final referenciasUrls = usarImgs
        ? <String>{...urlsHistorial, ...imagenesTurno}.toList()
        : const <String>[];

    final ok = await _ref.read(crearBriefProvider.notifier).crear(
          titulo: titulo,
          dropId: dropId,
          descripcion: descripcion,
          fechaLimite: fecha,
          colores: colores,
          tipografia: args['tipografia'] as String?,
          notasAdicionales: args['notas'] as String?,
          referenciasUrlsExistentes: referenciasUrls,
        );
    if (!ok) return const _ToolResult.err('no se pudo crear el brief');

    final extra = referenciasUrls.isNotEmpty
        ? ' con ${referenciasUrls.length} ${referenciasUrls.length == 1 ? "referencia" : "referencias"} visuales'
        : '';
    return _ToolResult.ok(
        'Listo, creé el brief «$titulo»$extra con entrega el ${_fechaLegible(fecha)}.');
  }

  // ── Ejecutores fase 2: aprobar/rechazar/drop/bono/anuncio ─────────────────

  Future<_ToolResult> _toolAprobarDisenio(Map<String, dynamic> args) async {
    final id = args['disenio_id'] as String?;
    if (id == null || id.isEmpty) {
      return const _ToolResult.err('falta diseño');
    }
    final titulo = await _buscarTituloDisenio(id);
    final ok = await _ref.read(aprobarDisenioProvider.notifier).aprobar(id);
    if (!ok) return const _ToolResult.err('no se pudo aprobar el diseño');
    return _ToolResult.ok(
        'Listo, aprobé el diseño «${titulo ?? "—"}». La diseñadora fue notificada.');
  }

  Future<_ToolResult> _toolRechazarDisenio(Map<String, dynamic> args) async {
    final id = args['disenio_id'] as String?;
    final feedback = args['feedback'] as String?;
    if (id == null || id.isEmpty) {
      return const _ToolResult.err('falta diseño');
    }
    if (feedback == null || feedback.trim().isEmpty) {
      return const _ToolResult.err('falta feedback');
    }
    final titulo = await _buscarTituloDisenio(id);
    final ok = await _ref
        .read(rechazarDisenioProvider.notifier)
        .rechazar(id, feedback.trim());
    if (!ok) return const _ToolResult.err('no se pudo rechazar el diseño');
    return _ToolResult.ok(
        'Listo, rechacé el diseño «${titulo ?? "—"}» con el feedback enviado.');
  }

  Future<_ToolResult> _toolCrearDrop(Map<String, dynamic> args) async {
    final nombre = args['nombre'] as String?;
    if (nombre == null || nombre.trim().isEmpty) {
      return const _ToolResult.err('falta nombre del drop');
    }
    final estado = (args['estado'] as String?) ?? 'planificacion';
    DateTime? fechaLanzamiento;
    final fechaStr = args['fecha_lanzamiento'] as String?;
    if (fechaStr != null && fechaStr.isNotEmpty) {
      fechaLanzamiento = DateTime.tryParse(fechaStr);
    }

    final ok = await _ref.read(gestionarDropsProvider.notifier).crear(
          nombre: nombre,
          estado: estado,
          concepto: args['concepto'] as String?,
          fechaLanzamiento: fechaLanzamiento,
        );
    if (!ok) return const _ToolResult.err('no se pudo crear el drop');
    final fechaTxt = fechaLanzamiento != null
        ? ' con lanzamiento el ${_fechaLegible(fechaLanzamiento)}'
        : '';
    return _ToolResult.ok('Listo, creé el drop «$nombre»$fechaTxt.');
  }

  Future<_ToolResult> _toolCrearBono(Map<String, dynamic> args) async {
    final userId = args['user_id'] as String?;
    final monto = args['monto'];
    final motivo = args['motivo'] as String?;
    if (userId == null || userId.isEmpty) {
      return const _ToolResult.err('falta usuario');
    }
    if (monto == null) return const _ToolResult.err('falta monto');
    if (motivo == null || motivo.trim().isEmpty) {
      return const _ToolResult.err('falta motivo');
    }

    final montoNum = monto is num
        ? monto.toDouble()
        : double.tryParse(monto.toString());
    if (montoNum == null || montoNum <= 0) {
      return const _ToolResult.err('monto inválido');
    }

    final periodo = (args['periodo'] as String?) ?? _periodoActual();
    final aprobadoPor =
        Supabase.instance.client.auth.currentUser?.id;

    try {
      await Supabase.instance.client.from('bonos').insert({
        'user_id': userId,
        'monto': montoNum,
        'motivo': motivo.trim(),
        'periodo': periodo,
        if (aprobadoPor != null) 'aprobado_por': aprobadoPor,
      });
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[crear bono] PG ERROR: ${e.code} ${e.message}');
      if (e.code == '42501' ||
          (e.message).toLowerCase().contains('row-level security')) {
        return const _ToolResult.err(
            'No tienes permiso para asignar bonos (solo CEO/RRHH).');
      }
      return _ToolResult.err(e.message);
    }

    final nombre = await _buscarNombreUsuario(userId);
    final montoFmt = montoNum % 1 == 0
        ? montoNum.toInt().toString()
        : montoNum.toStringAsFixed(2);

    // Notificación FCM al beneficiario (fire-and-forget).
    unawaited(pushNotif(
      userId: userId,
      titulo: '¡Recibiste un bono!',
      mensaje: 'S/ $montoFmt · ${motivo.trim()}',
      tipo: 'bono',
    ));

    return _ToolResult.ok(
        'Listo, asigné S/ $montoFmt a ${nombre ?? "—"} por «${motivo.trim()}» ($periodo).');
  }

  Future<_ToolResult> _toolAnuncioEquipo(Map<String, dynamic> args) async {
    final titulo = args['titulo'] as String?;
    final mensaje = args['mensaje'] as String?;
    if (titulo == null || titulo.trim().isEmpty) {
      return const _ToolResult.err('falta título');
    }
    if (mensaje == null || mensaje.trim().isEmpty) {
      return const _ToolResult.err('falta mensaje');
    }
    try {
      // IDs de todos los activos excepto el CEO emisor (no se autonotifica).
      final yo = Supabase.instance.client.auth.currentUser?.id;
      final rows = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('activo', true);
      final ids = (rows as List)
          .map((r) => r['id'] as String)
          .where((id) => id != yo)
          .toList();
      if (ids.isEmpty) {
        return const _ToolResult.err('no hay destinatarios activos');
      }
      await pushNotifMultiple(
        userIds: ids,
        titulo: titulo.trim(),
        mensaje: mensaje.trim(),
        tipo: 'sistema',
      );
      return _ToolResult.ok(
          'Listo, envié el anuncio a ${ids.length} ${ids.length == 1 ? "persona" : "personas"} del equipo.');
    } catch (e) {
      if (kDebugMode) print('[anuncio equipo] ERROR: $e');
      return const _ToolResult.err('no se pudo enviar el anuncio');
    }
  }

  String _periodoActual() {
    final n = DateTime.now();
    final q = ((n.month - 1) ~/ 3) + 1;
    return 'Q$q-${n.year}';
  }

  Future<String?> _buscarTituloDisenio(String id) async {
    try {
      final row = await Supabase.instance.client
          .from('disenios')
          .select('titulo')
          .eq('id', id)
          .maybeSingle();
      return row?['titulo'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String?> _buscarNombreUsuario(String id) async {
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('nombre')
          .eq('id', id)
          .maybeSingle();
      return row?['nombre'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _agregarMensajeIA(String texto) {
    state = state.copyWith(
      mensajes: [
        ...state.mensajes,
        MensajeChat(
          id: _nuevoId(),
          texto: texto,
          esUsuario: false,
          timestamp: DateTime.now(),
        ),
      ],
      isTyping: false,
    );
  }

  // Convierte el enum interno al string que el módulo calendario espera mostrar.
  String _mapearTipoEvento(String tipo) => switch (tipo) {
        'reunion' => 'Reunión de equipo',
        'lanzamiento_drop' => 'Lanzamiento de drop',
        'fecha_limite_disenio' => 'Fecha límite de diseño',
        'fecha_limite_tarea' => 'Fecha límite de tarea',
        'evento_especial' => 'Evento',
        _ => 'Evento',
      };

  String _colorPorTipo(String tipo) => switch (tipo) {
        'reunion' => '#3B82F6',
        'lanzamiento_drop' => '#FF4500',
        'fecha_limite_disenio' => '#8B5CF6',
        'fecha_limite_tarea' => '#F59E0B',
        'evento_especial' => '#A78BFA',
        _ => '#FF4500',
      };

  String _fechaLegible(DateTime d) {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${d.day} de ${meses[d.month]}';
  }
}

class _ToolResult {
  final bool ok;
  final String mensaje;
  const _ToolResult.ok(this.mensaje) : ok = true;
  const _ToolResult.err(this.mensaje) : ok = false;
}

final aiAsistenteProvider =
    StateNotifierProvider<AiAsistenteNotifier, AiAsistenteState>(
  (ref) => AiAsistenteNotifier(ref),
);

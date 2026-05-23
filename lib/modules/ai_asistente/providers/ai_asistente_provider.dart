// Provider del Modo Asistente — IA con tool calling.
//
// Diferente al ai_provider (chat informativo):
//  · Edge function ai-asistente devuelve `tipo: 'texto'` o `tipo: 'tool_call'`.
//  · Las acciones (crear_tarea, crear_evento, crear_brief) se ejecutan
//    CLIENT-SIDE llamando a los providers existentes — así se reutiliza
//    la lógica de notificaciones FCM, invalidación de caches y manejo de
//    errores que ya está testeada.
//  · crear_brief requiere confirmación previa del CEO. Las otras van directo.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../calendario/providers/calendario_provider.dart';
import '../../disenios/providers/briefs_provider.dart';
import '../../tareas/providers/tareas_provider.dart';
import 'ai_provider.dart' show MensajeChat;

// ─── Confirmación pendiente ────────────────────────────────────────────────────

class ConfirmacionPendiente {
  final String mensajeId; // id del mensaje bubble que muestra la confirmación
  final String tool;
  final Map<String, dynamic> args;
  final String resumen;

  const ConfirmacionPendiente({
    required this.mensajeId,
    required this.tool,
    required this.args,
    required this.resumen,
  });
}

// ─── Estado del asistente ──────────────────────────────────────────────────────

class AiAsistenteState {
  final List<MensajeChat> mensajes;
  final bool isTyping;
  final bool isEjecutando;
  final ConfirmacionPendiente? pendiente;
  final String? error;

  const AiAsistenteState({
    this.mensajes = const [],
    this.isTyping = false,
    this.isEjecutando = false,
    this.pendiente,
    this.error,
  });

  AiAsistenteState copyWith({
    List<MensajeChat>? mensajes,
    bool? isTyping,
    bool? isEjecutando,
    ConfirmacionPendiente? pendiente,
    bool clearPendiente = false,
    String? error,
    bool clearError = false,
  }) {
    return AiAsistenteState(
      mensajes: mensajes ?? this.mensajes,
      isTyping: isTyping ?? this.isTyping,
      isEjecutando: isEjecutando ?? this.isEjecutando,
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

  Future<void> enviar(String texto) async {
    final t = texto.trim();
    if (t.isEmpty) return;

    // Historial reciente para que la IA mantenga contexto.
    final prev = state.mensajes.length > 6
        ? state.mensajes.sublist(state.mensajes.length - 6)
        : List<MensajeChat>.from(state.mensajes);
    final historial = prev
        .map((m) => {
              'role': m.esUsuario ? 'user' : 'assistant',
              'content': m.texto,
            })
        .toList();

    final msgUser = MensajeChat(
      id: _nuevoId(),
      texto: t,
      esUsuario: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, msgUser],
      isTyping: true,
      clearError: true,
      clearPendiente: true, // cancela cualquier confirmación pendiente
    );

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-asistente',
        body: {
          'mensaje': t,
          'historial': historial,
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

      // Texto plano: pregunta de aclaración o respuesta conversacional.
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

  Future<void> _procesarToolCall(Map data) async {
    final tool = data['tool'] as String? ?? '';
    final args = Map<String, dynamic>.from(data['args'] as Map? ?? {});
    final requiere = data['requiere_confirmacion'] as bool? ?? false;
    final resumen = data['resumen'] as String? ?? '';

    if (requiere) {
      // Burbuja de confirmación: dejamos al CEO decidir.
      final mensajeId = _nuevoId();
      final pendiente = ConfirmacionPendiente(
        mensajeId: mensajeId,
        tool: tool,
        args: args,
        resumen: resumen,
      );
      // Añadimos un mensaje "marcador" en el historial para que la lista
      // sepa dónde renderizar la burbuja de confirmación.
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

    // Ejecución directa (crear_tarea, crear_evento).
    state = state.copyWith(isTyping: false, isEjecutando: true);
    final res = await _ejecutarTool(tool, args);
    state = state.copyWith(isEjecutando: false);
    if (res.ok) {
      _agregarMensajeIA(res.mensaje);
    } else {
      _agregarMensajeIA('No pude completar la acción: ${res.mensaje}');
    }
  }

  Future<void> confirmar() async {
    final p = state.pendiente;
    if (p == null) return;

    // Quitamos la burbuja de confirmación del historial.
    final sinPlaceholder =
        state.mensajes.where((m) => m.id != p.mensajeId).toList();
    state = state.copyWith(
      mensajes: sinPlaceholder,
      clearPendiente: true,
      isEjecutando: true,
    );

    final res = await _ejecutarTool(p.tool, p.args);
    state = state.copyWith(isEjecutando: false);
    if (res.ok) {
      _agregarMensajeIA(res.mensaje);
    } else {
      _agregarMensajeIA('No pude completar la acción: ${res.mensaje}');
    }
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

  // ── Ejecutores de tools ────────────────────────────────────────────────────

  Future<_ToolResult> _ejecutarTool(
      String tool, Map<String, dynamic> args) async {
    try {
      switch (tool) {
        case 'crear_tarea':
          return await _toolCrearTarea(args);
        case 'crear_evento':
          return await _toolCrearEvento(args);
        case 'crear_brief':
          return await _toolCrearBrief(args);
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
    final prioridad = args['prioridad'] as String? ?? 'media';
    if (titulo == null || titulo.trim().isEmpty) {
      return const _ToolResult.err('falta título');
    }
    if (area == null || area.isEmpty) {
      return const _ToolResult.err('falta área');
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

    // Buscar nombre del asignado para el mensaje de confirmación.
    String? nombreAsignado;
    final asignadoId = args['asignado_a_id'] as String?;
    if (asignadoId != null && asignadoId.isNotEmpty) {
      nombreAsignado = await _buscarNombreUsuario(asignadoId);
    }

    final partes = <String>['Listo, creé la tarea "$titulo"'];
    if (nombreAsignado != null) partes.add('asignada a $nombreAsignado');
    if (fecha != null) partes.add('con fecha límite ${_fechaLegible(fecha)}');
    return _ToolResult.ok('${partes.join(' ')}.');
  }

  Future<_ToolResult> _toolCrearEvento(Map<String, dynamic> args) async {
    final tipo = args['tipo'] as String? ?? 'Evento';
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
          tipo: tipo,
          titulo: titulo,
          fecha: fecha,
          hora: hora,
          lugar: args['lugar'] as String?,
          descripcion: args['descripcion'] as String?,
          colorHex: '#FF4500',
        );
    if (!ok) return const _ToolResult.err('no se pudo crear el evento');

    final horaTxt = hora != null
        ? ' a las ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
        : '';
    return _ToolResult.ok(
        'Listo, agregué "$titulo" al calendario para ${_fechaLegible(fecha)}$horaTxt.');
  }

  Future<_ToolResult> _toolCrearBrief(Map<String, dynamic> args) async {
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

    final ok = await _ref.read(crearBriefProvider.notifier).crear(
          titulo: titulo,
          dropId: dropId,
          descripcion: descripcion,
          fechaLimite: fecha,
          colores: colores,
          notasAdicionales: args['notas'] as String?,
        );
    if (!ok) return const _ToolResult.err('no se pudo crear el brief');

    return _ToolResult.ok(
        'Listo, creé el brief "$titulo" con entrega el ${_fechaLegible(fecha)}.');
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

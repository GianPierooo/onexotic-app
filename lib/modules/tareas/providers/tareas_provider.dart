import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tarea.dart';

// ─── Usuarios activos para asignar tareas ─────────────────────────────────────

class UsuarioSimple {
  final String id;
  final String nombre;
  final String rol;

  const UsuarioSimple({
    required this.id,
    required this.nombre,
    required this.rol,
  });

  factory UsuarioSimple.fromJson(Map<String, dynamic> json) => UsuarioSimple(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? 'Sin nombre',
        rol: json['rol'] as String? ?? '',
      );

  String get iniciales {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  String get rolLabel => switch (rol) {
        'ceo'        => 'CEO',
        'manager'    => 'Manager',
        'disenadora' => 'Diseñadora',
        'rrhh'       => 'RRHH',
        'produccion' => 'Producción',
        _            => rol,
      };
}

final usuariosActivosProvider = FutureProvider<List<UsuarioSimple>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('users')
        .select('id, nombre, rol')
        .eq('activo', true)
        .order('nombre');
    return (data as List).map((j) => UsuarioSimple.fromJson(j)).toList();
  } catch (e) {
    if (kDebugMode) print('[usuarios] ERROR: $e');
    return [];
  }
});

// ─── Filtro state ──────────────────────────────────────────────────────────────

class TareasFiltro {
  final String estado; // 'todas' | 'mis_tareas' | 'completadas'
  final String? area;  // null = todas las áreas

  const TareasFiltro({this.estado = 'todas', this.area});

  TareasFiltro copyWith({String? estado, String? area, bool clearArea = false}) {
    return TareasFiltro(
      estado: estado ?? this.estado,
      area: clearArea ? null : (area ?? this.area),
    );
  }
}

final tareasFiltroProvider = StateProvider<TareasFiltro>(
  (ref) => const TareasFiltro(),
);

// ─── Rol del usuario actual (para filtrar tareas) ─────────────────────────────

final rolActualProvider = FutureProvider<String>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'ceo';
  try {
    final data = await Supabase.instance.client
        .from('users')
        .select('rol')
        .eq('id', userId)
        .maybeSingle();
    return data?['rol'] as String? ?? 'ceo';
  } catch (_) {
    return 'ceo';
  }
});

// ─── Lista de tareas ───────────────────────────────────────────────────────────

final tareasProvider = FutureProvider<List<Tarea>>((ref) async {
  final filtro = ref.watch(tareasFiltroProvider);
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  final rol = ref.watch(rolActualProvider).maybeWhen(
    data: (r) => r,
    orElse: () => 'ceo',
  );
  final isAdmin = rol == 'ceo' || rol == 'manager';

  try {
    var query = client.from('tareas').select('*');

    // No-admin: SOLO ve sus propias tareas asignadas
    if (!isAdmin && userId != null) {
      query = query.eq('asignado_a', userId);
    }

    // Filtro de estado (se apila sobre el filtro de rol)
    if (filtro.estado == 'mis_tareas') {
      if (isAdmin && userId != null) query = query.eq('asignado_a', userId);
      query = query.eq('completado', false);
    } else if (filtro.estado == 'completadas') {
      query = query.eq('completado', true);
    }

    if (filtro.area != null) {
      query = query.eq('area', filtro.area!);
    }

    final data = await query.order('created_at', ascending: false);

    final tareas = (data as List).map((j) => Tarea.fromJson(j)).toList();

    // Ordenar: pendientes por prioridad primero, completadas al final
    const prioOrder = {'alta': 0, 'media': 1, 'baja': 2};
    tareas.sort((a, b) {
      if (a.completado != b.completado) return a.completado ? 1 : -1;
      return (prioOrder[a.prioridad] ?? 3).compareTo(prioOrder[b.prioridad] ?? 3);
    });

    if (kDebugMode) print('[tareas] cargadas: ${tareas.length} (filtro: ${filtro.estado}/${filtro.area})');
    return tareas;
  } catch (e, st) {
    if (kDebugMode) print('[tareas] ERROR: $e\n$st');
    rethrow;
  }
});

// ─── Completar / descompletar tarea ───────────────────────────────────────────

class ToggleTareaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ToggleTareaNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> toggle(String tareaId, {required bool completado}) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('tareas')
          .update({'completado': completado})
          .eq('id', tareaId);
      _ref.invalidate(tareasProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      if (kDebugMode) print('[toggle tarea] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final toggleTareaProvider =
    StateNotifierProvider<ToggleTareaNotifier, AsyncValue<void>>(
  (ref) => ToggleTareaNotifier(ref),
);

// ─── Crear tarea ──────────────────────────────────────────────────────────────

/// Resultado de creación: ok=true, o ok=false + error legible.
class CrearTareaResultado {
  final bool ok;
  final String? error;
  const CrearTareaResultado.ok() : ok = true, error = null;
  const CrearTareaResultado.err(this.error) : ok = false;
}

class CrearTareaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CrearTareaNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Inserta una nueva tarea en Supabase. Maneja nulls explícitamente y
  /// devuelve un resultado con error legible si algo falla (RLS, red,
  /// constraint, etc.) para que la UI lo muestre.
  Future<CrearTareaResultado> crear({
    required String titulo,
    required String area,
    required String prioridad,
    String? descripcion,
    DateTime? fechaLimite,
    String? asignadoA,
    String? imagenUrl,
  }) async {
    final tituloLimpio = titulo.trim();
    if (tituloLimpio.isEmpty) {
      return const CrearTareaResultado.err('Falta el título de la tarea');
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const CrearTareaResultado.err(
          'Tu sesión expiró. Vuelve a iniciar sesión.');
    }

    // Construye el payload SOLO con los campos que tienen valor real.
    // Campos opcionales (descripcion, fecha_limite, asignado_a, imagen_url)
    // se omiten si son null/vacíos para evitar enviar empty strings al INSERT.
    final desc = descripcion?.trim();
    final asign = asignadoA?.trim();
    final img = imagenUrl?.trim();

    final payload = <String, dynamic>{
      'titulo': tituloLimpio,
      'area': area,
      'prioridad': prioridad,
      'completado': false,
    };
    if (desc != null && desc.isNotEmpty) payload['descripcion'] = desc;
    if (asign != null && asign.isNotEmpty) payload['asignado_a'] = asign;
    if (img != null && img.isNotEmpty) payload['imagen_url'] = img;
    if (fechaLimite != null) {
      payload['fecha_limite'] =
          '${fechaLimite.year}-${fechaLimite.month.toString().padLeft(2, '0')}-${fechaLimite.day.toString().padLeft(2, '0')}';
    }

    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.from('tareas').insert(payload);
      _ref.invalidate(tareasProvider);
      state = const AsyncValue.data(null);
      return const CrearTareaResultado.ok();
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[crear tarea] PG ERROR: ${e.code} ${e.message}');
      state = AsyncValue.error(e, StackTrace.current);
      // RLS suele venir como 42501 / "new row violates row-level security"
      if (e.code == '42501' ||
          (e.message).toLowerCase().contains('row-level security')) {
        return const CrearTareaResultado.err(
            'No tienes permiso para crear tareas (solo CEO/Manager).');
      }
      return CrearTareaResultado.err(e.message);
    } catch (e) {
      if (kDebugMode) print('[crear tarea] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return CrearTareaResultado.err(e.toString());
    }
  }
}

final crearTareaProvider =
    StateNotifierProvider<CrearTareaNotifier, AsyncValue<void>>(
  (ref) => CrearTareaNotifier(ref),
);

// ─── Subir imagen de tarea ─────────────────────────────────────────────────────

Future<String?> uploadImagenTarea({
  required Uint8List bytes,
  required String ext,
}) async {
  try {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'tareas/$ts.$ext';
    await Supabase.instance.client.storage
        .from('tareas')
        .uploadBinary(path, bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));
    return Supabase.instance.client.storage.from('tareas').getPublicUrl(path);
  } catch (e) {
    if (kDebugMode) print('[upload tarea imagen] ERROR: $e');
    return null;
  }
}

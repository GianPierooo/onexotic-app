import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/fcm/push_helper.dart';
import '../models/brief.dart';
import 'disenios_provider.dart';
import 'historial_provider.dart';

// ─── Brief de un diseño ───────────────────────────────────────────────────────

final briefDeDisenioProvider =
    FutureProvider.family<Brief?, String>((ref, disenioId) async {
  try {
    final data = await Supabase.instance.client
        .from('briefs')
        .select()
        .eq('disenio_id', disenioId)
        .maybeSingle();
    return data != null ? Brief.fromJson(data) : null;
  } catch (e) {
    debugPrint('[briefs] ERROR: $e');
    return null;
  }
});

// ─── Drops disponibles (para pills del formulario) ───────────────────────────

final dropsDisponiblesProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('drops')
        .select('id, nombre')
        .order('nombre');
    return (data as List)
        .map((d) => {
              'id': d['id'] as String,
              'nombre': d['nombre'] as String,
            })
        .toList();
  } catch (e) {
    debugPrint('[drops] ERROR: $e');
    return [];
  }
});

// ─── Crear Brief + Diseño ─────────────────────────────────────────────────────

class CrearBriefNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CrearBriefNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> crear({
    required String titulo,
    required String? dropId,
    required String descripcion,
    required DateTime fechaLimite,
    List<String> colores = const [],
    String? tipografia,
    String? notasAdicionales,
    List<({Uint8List bytes, String ext})> imagenes = const [],
  }) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    try {
      final disenioRes = await client.from('disenios').insert({
        'titulo': titulo.trim(),
        'drop_id': dropId,
        'disenadora_id': userId,
        'estado': 'brief',
        'version': 1,
        'fecha_limite': _dateStr(fechaLimite),
      }).select('id').single();

      final disenioId = disenioRes['id'] as String;

      // Subir imágenes de referencia
      final referenciasUrls = <String>[];
      for (int i = 0; i < imagenes.length; i++) {
        try {
          final img = imagenes[i];
          final path = '$disenioId/${i + 1}.${img.ext}';
          await client.storage.from('referencias').uploadBinary(
                path,
                img.bytes,
                fileOptions: FileOptions(contentType: 'image/${img.ext}'),
              );
          referenciasUrls.add(
            client.storage.from('referencias').getPublicUrl(path),
          );
        } catch (e) {
          debugPrint('[subir imagen ref] ERROR: $e');
        }
      }

      await client.from('briefs').insert({
        'disenio_id': disenioId,
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'colores': colores,
        'referencias_urls': referenciasUrls,
        'tipografia':
            tipografia?.trim().isEmpty == true ? null : tipografia?.trim(),
        'notas_adicionales': notasAdicionales?.trim().isEmpty == true
            ? null
            : notasAdicionales?.trim(),
        'fecha_limite': _dateStr(fechaLimite),
        'creado_por': userId,
      });

      if (referenciasUrls.isNotEmpty) {
        await client.from('disenios').update({
          'thumbnail_url': referenciasUrls.first,
        }).eq('id', disenioId);
      }

      // Notificaciones cruzadas según rol creador:
      // · CEO/Manager → notifica a todas las diseñadoras
      // · Diseñadora  → notifica a todos los CEOs/Managers
      if (userId != null) {
        try {
          final userRow = await client
              .from('users')
              .select('rol, nombre')
              .eq('id', userId)
              .single();
          final rol = userRow['rol'] as String?;
          final nombreCreador = userRow['nombre'] as String? ?? 'Diseñadora';
          final fl = _dateStr(fechaLimite);

          if (rol == 'ceo' || rol == 'manager') {
            // CEO crea brief → notifica diseñadoras
            final diseniadoras = await client
                .from('users')
                .select('id')
                .eq('rol', 'disenadora')
                .eq('activo', true);
            await pushNotifMultiple(
              userIds: (diseniadoras as List).map((d) => d['id'] as String).toList(),
              titulo: 'Nuevo brief: $titulo',
              mensaje: 'Nuevo brief: $titulo · Entrega: $fl',
              tipo: 'disenio',
            );
          } else if (rol == 'disenadora') {
            // Diseñadora crea su propio brief → notifica CEOs/Managers
            final ceos = await client
                .from('users')
                .select('id')
                .inFilter('rol', ['ceo', 'manager'])
                .eq('activo', true);
            await pushNotifMultiple(
              userIds: (ceos as List).map((c) => c['id'] as String).toList(),
              titulo: 'Nuevo brief de $nombreCreador',
              mensaje: '$nombreCreador creó un brief: $titulo · Entrega: $fl',
              tipo: 'disenio',
            );
          }
        } catch (_) {}
      }

      await registrarHistorial(
        disenioId: disenioId,
        accion: 'Brief creado',
        descripcion: titulo.trim(),
        usuarioId: userId,
      );

      _ref.invalidate(diseniosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[crear brief] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final crearBriefProvider =
    StateNotifierProvider<CrearBriefNotifier, AsyncValue<void>>(
  (ref) => CrearBriefNotifier(ref),
);

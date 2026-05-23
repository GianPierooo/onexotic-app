
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avance.dart';
import 'disenios_provider.dart'
    show diseniosProvider, notificarDisenio, idsAllCeos;
import 'historial_provider.dart';

// ─── Lista de avances de un diseño ───────────────────────────────────────────

final avancesDeDisenioProvider =
    FutureProvider.family<List<DisenioAvance>, String>((ref, disenioId) async {
  ref.watch(diseniosProvider);
  try {
    final data = await Supabase.instance.client
        .from('disenio_avances')
        .select('*')
        .eq('disenio_id', disenioId)
        .order('created_at', ascending: false);
    return (data as List).map((j) => DisenioAvance.fromJson(j)).toList();
  } catch (e) {
    if (kDebugMode) print('[avances] ERROR: $e');
    return [];
  }
});

// ─── Subir avance ─────────────────────────────────────────────────────────────

class SubirAvanceNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  SubirAvanceNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> subir({
    required String disenioId,
    required String disenioTitulo,
    required Uint8List bytes,
    required String ext,
    String? nota,
    bool esFinal = false,
  }) async {
    state = const AsyncValue.loading();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '$disenioId/avance_$ts.$ext';
      await client.storage.from('avances').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext'),
          );
      final imagenUrl = client.storage.from('avances').getPublicUrl(path);

      await client.from('disenio_avances').insert({
        'disenio_id': disenioId,
        'imagen_url': imagenUrl,
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        'subido_por': userId,
      });

      if (!esFinal) {
        // Avance de proceso → cambia estado a 'avance' y notifica CEO
        await client.from('disenios').update({
          'estado': 'avance',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', disenioId);

        final ceos = await idsAllCeos();
        for (final id in ceos) {
          await notificarDisenio(id, 'Boceto listo para revisar',
              'Boceto de $disenioTitulo listo para revisar');
        }
      } else {
        // Versión final en 'revision' → actualiza thumbnail y notifica CEO
        await client.from('disenios').update({
          'thumbnail_url': imagenUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', disenioId);

        final ceos = await idsAllCeos();
        for (final id in ceos) {
          await notificarDisenio(id, '¡Diseño final listo!',
              'El diseño final de $disenioTitulo está listo para aprobar');
        }
      }

      await registrarHistorial(
        disenioId: disenioId,
        accion: esFinal ? 'Versión final subida' : 'Avance subido',
        descripcion: nota?.trim().isNotEmpty == true ? nota!.trim() : null,
        usuarioId: userId,
      );

      _ref.invalidate(diseniosProvider);
      _ref.invalidate(historialDeDisenioProvider(disenioId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      if (kDebugMode) print('[subir avance] ERROR: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final subirAvanceProvider =
    StateNotifierProvider<SubirAvanceNotifier, AsyncValue<void>>(
  (ref) => SubirAvanceNotifier(ref),
);

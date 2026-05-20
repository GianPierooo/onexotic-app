// SQL requerido en Supabase antes de usar este módulo:
//
// CREATE TABLE IF NOT EXISTS disenio_historial (
//   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
//   disenio_id uuid NOT NULL REFERENCES disenios(id) ON DELETE CASCADE,
//   accion text NOT NULL,
//   descripcion text,
//   usuario_id uuid REFERENCES users(id),
//   created_at timestamptz DEFAULT now()
// );
// ALTER TABLE disenio_historial ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "auth_read_historial" ON disenio_historial
//   FOR SELECT TO authenticated USING (true);
// CREATE POLICY "auth_insert_historial" ON disenio_historial
//   FOR INSERT TO authenticated WITH CHECK (true);
//
// ALTER TABLE productos ADD COLUMN IF NOT EXISTS disenio_id uuid REFERENCES disenios(id);

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historial.dart';

// ─── Historial de un diseño ───────────────────────────────────────────────────

final historialDeDisenioProvider =
    FutureProvider.family<List<DisenioHistorial>, String>((ref, disenioId) async {
  try {
    final data = await Supabase.instance.client
        .from('disenio_historial')
        .select('*, users(nombre)')
        .eq('disenio_id', disenioId)
        .order('created_at', ascending: true);
    return (data as List).map((j) => DisenioHistorial.fromJson(j)).toList();
  } catch (e) {
    if (kDebugMode) print('[historial] ERROR: $e');
    return [];
  }
});

// ─── Helper: insertar entrada en historial ────────────────────────────────────

Future<void> registrarHistorial({
  required String disenioId,
  required String accion,
  String? descripcion,
  String? usuarioId,
}) async {
  try {
    await Supabase.instance.client.from('disenio_historial').insert({
      'disenio_id': disenioId,
      'accion': accion,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      if (usuarioId != null) 'usuario_id': usuarioId,
    });
  } catch (e) {
    if (kDebugMode) print('[historial insert] ERROR: $e');
  }
}

// ─── Conteo de productos generados desde un diseño ───────────────────────────

final productosDeDisenioProvider =
    FutureProvider.family<int, String>((ref, disenioId) async {
  try {
    final data = await Supabase.instance.client
        .from('productos')
        .select('id')
        .eq('disenio_id', disenioId);
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

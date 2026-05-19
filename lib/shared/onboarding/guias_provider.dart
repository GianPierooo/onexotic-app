// SQL requerido en Supabase antes de usar este módulo:
//
// CREATE TABLE IF NOT EXISTS guias_vistas (
//   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
//   user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
//   modulo text NOT NULL,
//   vista_at timestamptz DEFAULT now(),
//   UNIQUE(user_id, modulo)
// );
// ALTER TABLE guias_vistas ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "user_own_guias" ON guias_vistas
//   FOR ALL TO authenticated
//   USING (user_id = auth.uid())
//   WITH CHECK (user_id = auth.uid());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Verifica si el usuario ya vio esta guía ──────────────────────────────────

final guiaVistaProvider =
    FutureProvider.family<bool, String>((ref, modulo) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return true; // no logueado → no mostrar
  try {
    final data = await Supabase.instance.client
        .from('guias_vistas')
        .select('id')
        .eq('user_id', userId)
        .eq('modulo', modulo)
        .maybeSingle();
    return data != null; // true = ya la vio
  } catch (_) {
    return true; // en error, no mostrar para no molestar
  }
});

// ─── Marca la guía como vista ─────────────────────────────────────────────────

Future<void> marcarGuiaVista(String modulo) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  try {
    await Supabase.instance.client.from('guias_vistas').upsert(
      {'user_id': userId, 'modulo': modulo},
      onConflict: 'user_id,modulo',
    );
  } catch (_) {}
}

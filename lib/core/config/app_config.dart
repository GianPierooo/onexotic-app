// Credenciales públicas de OnExotic — seguras para estar en código.
//
// Supabase anon key y VAPID key son públicas por diseño:
//   • Supabase protege los datos con RLS, no con la anon key.
//   • VAPID key es solo un identificador público de push web.
//
// NUNCA pongas aquí: service_role key, JWT secrets, claves de Firebase Admin.

class AppConfig {
  // ── Supabase ─────────────────────────────────────────────────────────────────
  static const supabaseUrl = 'https://gxzajbxumilshvrpwcnx.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4emFqYnh1bWlsc2h2cnB3Y254Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NTExOTUsImV4cCI6MjA5NDUyNzE5NX0'
      '.HN22wDBXgM_BPK-nqR0uV-yBdwN8UAmI36SQ9O8YI8k';

  // ── Firebase Web Push (VAPID) ─────────────────────────────────────────────────
  // Firebase Console → Cloud Messaging → Configuración web → Certificados push web
  static const firebaseVapidKey =
      'BJ0zhllwrm4j9ahTwTFIooonbchZDoqrYsVsWCGZ60CD8kFDydpYxwFEvtLB527olkUS2xDdGSxRAecegtywA2Q';
}

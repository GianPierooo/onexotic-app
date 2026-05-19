import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Background handler (debe ser función top-level, no un método de clase) ───
// Se invoca cuando llega un push con la app cerrada o en segundo plano.
@pragma('vm:entry-point')
Future<void> onFcmBackgroundMessage(RemoteMessage message) async {
  // Firebase ya muestra la notificación del sistema automáticamente
  // a partir del campo notification{} del payload FCM.
  // Este handler es para lógica adicional (ej. guardar en local storage).
  debugPrint(
    '[FCM background] ${message.notification?.title} — ${message.notification?.body}',
  );
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Inicializa FCM: permisos, handlers y opciones de presentación.
  /// Llamar en main() DESPUÉS de Firebase.initializeApp().
  static Future<void> init() async {
    // Registra el handler de mensajes en segundo plano / app cerrada
    FirebaseMessaging.onBackgroundMessage(onFcmBackgroundMessage);

    // Solicitar permisos (iOS y web los requieren explícitamente)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] permiso: ${settings.authorizationStatus.name}');

    // Mostrar notificaciones mientras la app está en primer plano
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler para mensajes con la app en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FCM foreground] ${message.notification?.title}: ${message.notification?.body}',
      );
      // La UI se actualizará automáticamente via Supabase Realtime
      // (notificacionesStreamProvider ya escucha inserts en la tabla).
    });

    // Handler para cuando el usuario toca la notificación del sistema
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM tap] tipo=${message.data["tipo"]}');
      // TODO: navegar a la pantalla correspondiente según message.data["tipo"]
    });
  }

  /// Obtiene el FCM token y lo persiste en tabla users.fcm_token.
  static Future<void> saveToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      String? token;
      if (kIsWeb) {
        // VAPID key: Firebase Console → Cloud Messaging → Certificados push web
        final vapidKey = dotenv.env['FIREBASE_VAPID_KEY'];
        if (vapidKey == null || vapidKey.isEmpty) {
          debugPrint('[FCM] FIREBASE_VAPID_KEY no definida en .env — skip web push');
          return;
        }
        token = await _messaging.getToken(vapidKey: vapidKey);
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('[FCM] token guardado (${token.substring(0, 20)}...)');
    } catch (e) {
      debugPrint('[FCM] ERROR guardando token: $e');
    }
  }

  /// Escucha renovaciones de token y las persiste automáticamente.
  static void listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('[FCM] token renovado');
      await saveToken();
    });
  }
}

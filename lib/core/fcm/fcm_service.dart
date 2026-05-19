import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler de mensajes en background — debe ser una función top-level.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM background] ${message.notification?.title}: ${message.notification?.body}');
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Inicializa FCM: permisos + handlers.
  /// Llama esto en main() después de Firebase.initializeApp().
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Permisos (iOS y web los necesitan explícitamente)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permiso: ${settings.authorizationStatus}');

    // Mensajes en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM foreground] ${message.notification?.title}');
    });

    // Web: habilita notificaciones en primer plano
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Obtiene el token FCM del dispositivo y lo guarda en Supabase.
  static Future<void> saveToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Para web necesita la VAPID key de Firebase Console →
      // Cloud Messaging → Configuración web → Certificados push web
      final token = kIsWeb
          ? await _messaging.getToken(
              vapidKey: 'REEMPLAZA_VAPID_KEY',
            )
          : await _messaging.getToken();

      if (token == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('[FCM] token guardado: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('[FCM] ERROR guardando token: $e');
    }
  }

  /// Escucha cuando el token se renueva y lo re-guarda.
  static void listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] token renovado');
      await saveToken();
    });
  }
}

import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'pending_route_notifier.dart';

// ─── Background handler (debe ser función top-level, no un método de clase) ───
// Se invoca cuando llega un push con la app cerrada o en segundo plano.
@pragma('vm:entry-point')
Future<void> onFcmBackgroundMessage(RemoteMessage message) async {
  // No se necesita hacer nada más: FCM muestra la notificación
  // automáticamente gracias al canal creado con IMPORTANCE_HIGH.
  // El canal fue registrado al inicio del app, Android lo recuerda.
  if (kDebugMode) print(
    '[FCM background] ${message.notification?.title}',
  );
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Inicializa FCM: permisos, handlers y opciones de presentación.
  /// Llamar en main() DESPUÉS de Firebase.initializeApp().
  static Future<void> init() async {
    // El canal debe existir ANTES de que llegue cualquier push — si no,
    // Android cae al canal default silencioso y la priority:"high" del
    // payload FCM queda ignorada.
    await _crearCanalAndroid();

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
    if (kDebugMode) print('[FCM] permiso: ${settings.authorizationStatus.name}');

    // En iOS garantiza que el token APNs se genere automáticamente.
    await _messaging.setAutoInitEnabled(true);

    // Mostrar notificaciones mientras la app está en primer plano
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler para mensajes con la app en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) print(
        '[FCM foreground] ${message.notification?.title}: ${message.notification?.body}',
      );
      // La UI se actualizará automáticamente via Supabase Realtime
      // (notificacionesStreamProvider ya escucha inserts en la tabla).
    });

    // Handler para cuando el usuario toca la notificación del sistema con la
    // app en background. Mapea el tipo a una ruta y la deposita en
    // pendingRouteNotifier — AppShell lo consume cuando el router esté listo.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) print('[FCM tap] tipo=${message.data["tipo"]}');
      final ruta = _routeForTipo(message.data["tipo"] as String?);
      if (ruta != null) pendingRouteNotifier.value = ruta;
    });

    // Cold start: si la app fue abierta tocando un push estando terminada,
    // FirebaseMessaging guarda ese mensaje en getInitialMessage(). No llega
    // por el listener de onMessageOpenedApp.
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      if (kDebugMode) print('[FCM cold-start] tipo=${initialMsg.data["tipo"]}');
      final ruta = _routeForTipo(initialMsg.data["tipo"] as String?);
      if (ruta != null) pendingRouteNotifier.value = ruta;
    }

    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      final plugin = FlutterLocalNotificationsPlugin();
      final channels = await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationChannels();
      print('[FCM] canales registrados: ${channels?.map((c) => c.id).toList()}');
    }
  }

  /// Registra el canal Android para FCM. Android cachea el canal por id, así
  /// que esta llamada es idempotente: si ya existe, ignora la nueva config.
  /// Si el canal fue creado antes con otras propiedades hay que desinstalar
  /// la app para que el sistema acepte los nuevos valores.
  static Future<void> _crearCanalAndroid() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final plugin = FlutterLocalNotificationsPlugin();
    final channel = AndroidNotificationChannel(
      'onexotic_default',
      'OnExotic',
      description: 'Notificaciones del equipo OnExotic',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
      enableLights: true,
      ledColor: const Color(0xFFFF4500),
      showBadge: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    if (kDebugMode) print('[FCM] canal Android creado: onexotic_default');
  }

  /// Mapea el campo `tipo` del payload data a la ruta destino dentro de la app.
  /// Devuelve null para tipos que no requieren navegación (ej. 'sistema').
  static String? _routeForTipo(String? tipo) => switch (tipo) {
        'disenio'    => '/disenios',
        'tarea'      => '/tareas',
        'inventario' => '/inventario',
        'asistencia' => '/asistencia',
        'bono'       => '/equipo',
        'chat'       => '/equipo',
        _            => null,
      };

  /// Obtiene el FCM token y lo persiste en tabla users.fcm_token.
  static Future<void> saveToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(
          vapidKey: AppConfig.firebaseVapidKey,
        );
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      if (kDebugMode) print('[FCM] token guardado (${token.substring(0, 20)}...)');
    } catch (e) {
      if (kDebugMode) print('[FCM] ERROR guardando token: $e');
    }
  }

  /// Escucha renovaciones de token y las persiste automáticamente.
  static void listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      if (kDebugMode) print('[FCM] token renovado');
      await saveToken();
    });
  }
}

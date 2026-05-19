// ─── Firebase Options — generado por: flutterfire configure ──────────────────
// TODO: Ejecuta `flutterfire configure` para regenerar este archivo
//       con tus credenciales reales, o rellena manualmente los valores
//       que encuentras en Firebase Console → Configuración del proyecto.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ─────────────────────────────────────────────────────────────────────
  // Firebase Console → Proyecto → Configuración → Tus apps → App web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'REEMPLAZA_WEB_API_KEY',
    appId:             'REEMPLAZA_WEB_APP_ID',
    messagingSenderId: 'REEMPLAZA_SENDER_ID',
    projectId:         'REEMPLAZA_PROJECT_ID',
    authDomain:        'REEMPLAZA_PROJECT_ID.firebaseapp.com',
    storageBucket:     'REEMPLAZA_PROJECT_ID.appspot.com',
  );

  // ── Android ──────────────────────────────────────────────────────────────────
  // Firebase Console → Proyecto → Configuración → Tus apps → App Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'REEMPLAZA_ANDROID_API_KEY',
    appId:             'REEMPLAZA_ANDROID_APP_ID',
    messagingSenderId: 'REEMPLAZA_SENDER_ID',
    projectId:         'REEMPLAZA_PROJECT_ID',
    storageBucket:     'REEMPLAZA_PROJECT_ID.appspot.com',
  );

  // ── iOS ──────────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'REEMPLAZA_IOS_API_KEY',
    appId:             'REEMPLAZA_IOS_APP_ID',
    messagingSenderId: 'REEMPLAZA_SENDER_ID',
    projectId:         'REEMPLAZA_PROJECT_ID',
    storageBucket:     'REEMPLAZA_PROJECT_ID.appspot.com',
    iosBundleId:       'com.onexotic.onexoticApp',
  );
}

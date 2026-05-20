// ─── Firebase Options — OnExotic ─────────────────────────────────────────────
//
// Android: valores extraídos de android/app/google-services.json ✓
// Web:     ejecuta `flutterfire configure` o copia manualmente desde
//          Firebase Console → Proyecto onexotic-49e29 → Tus apps → App web
// iOS:     agrega ios/Runner/GoogleService-Info.plist y ejecuta flutterfire

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  // ── Android ───────────────────────────────────────────────────────────────────
  // Fuente: android/app/google-services.json (proyecto onexotic-49e29)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyD8l_U0vJ3rR8XpONfeGVKHvmVJWDmzQYI',
    appId:             '1:982678191452:android:d393ddc5f6a597d9b5d599',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
  );

  // ── Web ───────────────────────────────────────────────────────────────────────
  // Firebase Console → onexotic-49e29 → Configuración → Tus apps → App web
  // Reemplaza SOLO los valores REEMPLAZA_* — el resto ya está correcto.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'REEMPLAZA_WEB_API_KEY',
    appId:             'REEMPLAZA_WEB_APP_ID',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    authDomain:        'onexotic-49e29.firebaseapp.com',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
  );

  // ── iOS ───────────────────────────────────────────────────────────────────────
  // Agrega ios/Runner/GoogleService-Info.plist desde Firebase Console,
  // luego ejecuta: flutterfire configure --project=onexotic-49e29
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'REEMPLAZA_IOS_API_KEY',
    appId:             'REEMPLAZA_IOS_APP_ID',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
    iosBundleId:       'com.onexotic.onexoticApp',
  );
}

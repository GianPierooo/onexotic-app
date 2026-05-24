// ─── Firebase Options — OnExotic ─────────────────────────────────────────────
//
// Generado y mantenido por `flutterfire configure --project=onexotic-49e29`.
// Android: configurado ✓
// Web:     configurado ✓
// iOS:     pendiente (requiere Apple Developer Program + APNs). main.dart
//          detecta el prefijo REEMPLAZA y omite Firebase.initializeApp.

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

  // ── Android ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyD8l_U0vJ3rR8XpONfeGVKHvmVJWDmzQYI',
    appId:             '1:982678191452:android:d393ddc5f6a597d9b5d599',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
  );

  // ── Web ─────────────────────────────────────────────────────────────────────
  // Si actualizas aquí, sincroniza también web/firebase-messaging-sw.js.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyB8tp6iI8g5cUHkZCW8xo9fTZX6qNuUefs',
    appId:             '1:982678191452:web:694a5b7b79c5c90fb5d599',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    authDomain:        'onexotic-49e29.firebaseapp.com',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
  );

  // ── iOS ─────────────────────────────────────────────────────────────────────
  // Pendiente: ejecutar `flutterfire configure` con iOS marcado cuando esté
  // listo el Apple Developer Program. main.dart omite init si detecta REEMPLAZA.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'REEMPLAZA_IOS_API_KEY',
    appId:             'REEMPLAZA_IOS_APP_ID',
    messagingSenderId: '982678191452',
    projectId:         'onexotic-49e29',
    storageBucket:     'onexotic-49e29.firebasestorage.app',
    iosBundleId:       'com.onexotic.onexoticApp',
  );
}

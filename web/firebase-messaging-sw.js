// Service Worker para Firebase Cloud Messaging (background messages en web)
// Este archivo DEBE estar en la raíz del dominio (web/).
// Valores sincronizados con lib/firebase_options.dart → web.

importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyB8tp6iI8g5cUHkZCW8xo9fTZX6qNuUefs',
  authDomain:        'onexotic-49e29.firebaseapp.com',
  projectId:         'onexotic-49e29',
  storageBucket:     'onexotic-49e29.firebasestorage.app',
  messagingSenderId: '982678191452',
  appId:             '1:982678191452:web:694a5b7b79c5c90fb5d599',
});

const messaging = firebase.messaging();

// Notificaciones en background (app minimizada o cerrada)
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const title = payload.notification?.title ?? 'OnExotic';
  const body  = payload.notification?.body  ?? '';

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.notification_id ?? 'onexotic-push',
  });
});

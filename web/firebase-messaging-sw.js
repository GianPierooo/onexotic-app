// Service Worker para Firebase Cloud Messaging (background messages en web)
// Este archivo DEBE estar en la raíz del dominio (web/).
//
// TODO: Reemplaza los valores de firebaseConfig con los de tu proyecto:
//   Firebase Console → Configuración del proyecto → Tus apps → App web

importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'REEMPLAZA_WEB_API_KEY',
  authDomain:        'REEMPLAZA_PROJECT_ID.firebaseapp.com',
  projectId:         'REEMPLAZA_PROJECT_ID',
  storageBucket:     'REEMPLAZA_PROJECT_ID.appspot.com',
  messagingSenderId: 'REEMPLAZA_SENDER_ID',
  appId:             'REEMPLAZA_WEB_APP_ID',
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

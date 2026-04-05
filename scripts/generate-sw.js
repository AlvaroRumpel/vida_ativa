#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const env = process.argv[2] || 'prod';

const configs = {
  staging: {
    apiKey: 'AIzaSyAUBQohx_R-v2nauF4BduWkLWOgb5GJb28',
    authDomain: 'vida-ativa-staging.firebaseapp.com',
    projectId: 'vida-ativa-staging',
    storageBucket: 'vida-ativa-staging.firebasestorage.app',
    messagingSenderId: '901130410262',
    appId: '1:901130410262:web:afe75feef948f108b99837',
  },
  prod: {
    apiKey: 'AIzaSyA-fBLM5XTSjQhBKCwIAnh793S7lKcNfUA',
    authDomain: 'vida-ativa-94ba0.firebaseapp.com',
    projectId: 'vida-ativa-94ba0',
    storageBucket: 'vida-ativa-94ba0.firebasestorage.app',
    messagingSenderId: '1020952880974',
    appId: '1:1020952880974:web:05faae57258c3914b8e01f',
  },
};

const config = configs[env];
if (!config) {
  console.error(`Unknown env "${env}". Use "staging" or "prod".`);
  process.exit(1);
}

const output = `// GENERATED — do not edit. Run: node scripts/generate-sw.js [staging|prod]
importScripts('https://www.gstatic.com/firebasejs/10.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: '${config.apiKey}',
  authDomain: '${config.authDomain}',
  projectId: '${config.projectId}',
  storageBucket: '${config.storageBucket}',
  messagingSenderId: '${config.messagingSenderId}',
  appId: '${config.appId}',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notificationTitle = message.notification?.title || 'Nova Reserva';
  const notificationOptions = {
    body: message.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: message.data || {},
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const link = event.notification.data?.link || '/admin';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes('/admin') && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(link);
    })
  );
});
`;

const outPath = path.resolve(__dirname, '../web/firebase-messaging-sw.js');
fs.writeFileSync(outPath, output, 'utf8');
console.log(`Generated ${outPath} for env=${env} (projectId: ${config.projectId})`);

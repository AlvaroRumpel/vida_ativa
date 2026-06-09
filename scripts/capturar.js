/**
 * capturar.js — Tira screenshots da staging e salva em /screenshots.
 *
 * Uso:
 *   node capturar.js
 *
 * Pré-requisitos: npm install puppeteer-core firebase-admin
 *
 * Auth: usa Firebase Admin SDK para gerar custom token → troca por idToken via
 * REST API → injeta auth state no IndexedDB antes do Flutter carregar.
 * Sem senha, sem Google OAuth.
 */

const puppeteer = require('puppeteer-core');
const admin = require('firebase-admin');
const path = require('path');

const BRAVE_PATH =
  'C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe';

const OUT_DIR = path.join(__dirname, '..', 'screenshots');
const BASE = 'https://vida-ativa-staging.web.app';
const STAGING_API_KEY = 'AIzaSyAUBQohx_R-v2nauF4BduWkLWOgb5GJb28';
const USER_UID = 'ibDI0OYWEVhsib9EqTBSRt1aOfz2';

const TELAS_PUBLICAS = [
  { nome: '01_splash',   url: `${BASE}/#/splash`,    aguardar: 3000 },
  { nome: '02_login',    url: `${BASE}/#/login`,     aguardar: 3000 },
  { nome: '03_register', url: `${BASE}/#/register`,  aguardar: 3000 },
];

const TELAS_CLIENTE = [
  { nome: '04_home',     url: `${BASE}/#/home`,      aguardar: 5000 },
  { nome: '05_bookings', url: `${BASE}/#/bookings`,  aguardar: 5000 },
  { nome: '06_profile',  url: `${BASE}/#/profile`,   aguardar: 4000 },
];

const TELAS_ADMIN = [
  { nome: '07_admin_dashboard', url: `${BASE}/#/admin`, aguardar: 6000 },
];

async function esperar(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function screenshot(page, nome, aguardar) {
  await esperar(aguardar);
  const arquivo = path.join(OUT_DIR, `${nome}.png`);
  await page.screenshot({ path: arquivo, fullPage: false });
  console.log(`✓ ${nome}.png`);
}

async function obterAuthData() {
  const serviceAccount = require('./vida-ativa-staging-firebase-adminsdk-fbsvc-07010ee1af.json');
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

  console.log('🔑 Gerando custom token...');
  const customToken = await admin.auth().createCustomToken(USER_UID);

  // Trocar custom token por idToken via REST
  const signInResp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${STAGING_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    }
  );
  const { idToken, refreshToken, expiresIn } = await signInResp.json();

  // Buscar perfil do usuário
  const lookupResp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${STAGING_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken }),
    }
  );
  const { users } = await lookupResp.json();
  const user = users[0];

  console.log(`✓ Auth obtida para: ${user.email}`);

  return {
    uid: user.localId,
    email: user.email,
    displayName: user.displayName || '',
    photoURL: user.photoUrl || null,
    emailVerified: user.emailVerified || false,
    providerData: user.providerUserInfo || [],
    createdAt: user.createdAt,
    lastLoginAt: user.lastLoginAt,
    idToken,
    refreshToken,
    expirationTime: Date.now() + parseInt(expiresIn) * 1000,
  };
}

// Injeta auth state no IndexedDB antes do Flutter inicializar
async function injetarAuth(page, authData) {
  await page.evaluateOnNewDocument(({ apiKey, auth }) => {
    const DB_NAME = 'firebaseLocalStorageDb';
    const STORE_NAME = 'firebaseLocalStorage';
    const KEY = `firebase:authUser:${apiKey}:[DEFAULT]`;

    const authState = {
      uid: auth.uid,
      email: auth.email,
      emailVerified: auth.emailVerified,
      displayName: auth.displayName,
      photoURL: auth.photoURL,
      isAnonymous: false,
      providerData: auth.providerData,
      stsTokenManager: {
        refreshToken: auth.refreshToken,
        accessToken: auth.idToken,
        expirationTime: auth.expirationTime,
      },
      createdAt: auth.createdAt,
      lastLoginAt: auth.lastLoginAt,
      apiKey,
      appName: '[DEFAULT]',
    };

    const openReq = indexedDB.open(DB_NAME, 1);
    openReq.onupgradeneeded = (e) => {
      e.target.result.createObjectStore(STORE_NAME, { keyPath: 'fbase_key' });
    };
    openReq.onsuccess = (e) => {
      const db = e.target.result;
      const tx = db.transaction(STORE_NAME, 'readwrite');
      tx.objectStore(STORE_NAME).put({ fbase_key: KEY, value: authState });
    };
  }, { apiKey: STAGING_API_KEY, auth: authData });
}

(async () => {
  // Obter tokens Firebase antes de abrir browser
  const authData = await obterAuthData();

  const browser = await puppeteer.launch({
    executablePath: BRAVE_PATH,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1440,900'],
    defaultViewport: { width: 1440, height: 900 },
  });

  // ── Telas públicas (nova page sem auth) ────────────────────────────────────
  console.log('\n── Telas públicas ──');
  const pagePublica = await browser.newPage();
  for (const tela of TELAS_PUBLICAS) {
    await pagePublica.goto(tela.url, { waitUntil: 'networkidle0', timeout: 30000 });
    await screenshot(pagePublica, tela.nome, tela.aguardar);
  }
  await pagePublica.close();

  // ── Telas autenticadas (nova page com auth injetada) ───────────────────────
  const pageAuth = await browser.newPage();
  await injetarAuth(pageAuth, authData);

  console.log('\n── Telas cliente ──');
  for (const tela of TELAS_CLIENTE) {
    await pageAuth.goto(tela.url, { waitUntil: 'networkidle2', timeout: 30000 });
    await screenshot(pageAuth, tela.nome, tela.aguardar);
  }

  console.log('\n── Telas admin ──');
  for (const tela of TELAS_ADMIN) {
    await pageAuth.goto(tela.url, { waitUntil: 'networkidle2', timeout: 30000 });
    await screenshot(pageAuth, tela.nome, tela.aguardar);
  }

  // Admin — abas internas
  const abas = [
    { nome: '08_admin_slots',      x: 187, y: 76 },
    { nome: '09_admin_bloqueios',  x: 274, y: 76 },
    { nome: '10_admin_reservas',   x: 369, y: 76 },
    { nome: '11_admin_usuarios',   x: 461, y: 76 },
    { nome: '12_admin_precos',     x: 547, y: 76 },
    { nome: '13_admin_ajustes',    x: 628, y: 76 },
  ];
  for (const aba of abas) {
    await pageAuth.goto(`${BASE}/#/admin`, { waitUntil: 'networkidle2', timeout: 30000 });
    await esperar(3000);
    await pageAuth.mouse.click(aba.x, aba.y);
    await screenshot(pageAuth, aba.nome, 4000);
  }

  await pageAuth.close();
  await browser.close();
  console.log('\n✅ Concluído! PNGs salvos em:', OUT_DIR);
})();

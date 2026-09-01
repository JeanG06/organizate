// ============================================================
// Script de build: genera js/env.js a partir de variables de entorno.
// Usado por Vercel (build) y manualmente para desarrollo local.
//
//   env.js crea: window.SUPABASE_CONFIG = { url, anonKey }
//
// Si las variables de entorno no existen, copia js/env.example.js
// para que el frontend avise que falta configurar.
// ============================================================
const fs = require('fs');
const path = require('path');

const URL_ENV = process.env.SUPABASE_URL || '';
const KEY_ANON = process.env.SUPABASE_ANON_KEY || '';

const esValido = URL_ENV && KEY_ANON && URL_ENV.indexOf('PEGA') === -1 && KEY_ANON.indexOf('PEGA') === -1;

const salida = esValido
  ? `// Generado automaticamente por el build. No editar a mano.\nwindow.SUPABASE_CONFIG = ${JSON.stringify({ url: URL_ENV, anonKey: KEY_ANON }, null, 2)};\n`
  : fs.readFileSync(path.join(__dirname, '..', 'js', 'env.example.js'), 'utf8');

const destino = path.join(__dirname, '..', 'js', 'env.js');
fs.writeFileSync(destino, salida);
console.log('[build-env] env.js generado (' + (esValido ? 'con credenciales' : 'plantilla sin credenciales') + ')');

// ============================================================
// CONFIGURACION DE SUPABASE (sin secretos en el repo)
//
// Este archivo NO contiene datos. Las credenciales reales van en
// js/env.js (que está en .gitignore y NO se sube a GitHub).
//
// js/env.js debe definir:
//   window.SUPABASE_CONFIG = { url: 'https://...', anonKey: 'eyJ...' }
// ============================================================

const SUPABASE_URL = (window.SUPABASE_CONFIG && window.SUPABASE_CONFIG.url) || 'SIN_CONFIGURAR';
const SUPABASE_ANON_KEY = (window.SUPABASE_CONFIG && window.SUPABASE_CONFIG.anonKey) || 'SIN_CONFIGURAR';

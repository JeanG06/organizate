# OrganizaTe ♟️

Tablero de trabajo tipo ajedrez para TI & Hoteles.
Un calendario mensual donde tus actividades son **fichas** que visualizas de golpe, mueves (drag & drop) y en las que registras el **trabajo real hecho**.

## Concepto
- **Calendario-tablero** tipo corcho/pizarrón de **post-its**: la grilla mensual es el tablero y las actividades son **post-its** que pegas y mueves.
- Cada **post-it** = una actividad, con **emoji/ícono**, color **por hotel** (5 hoteles).
- Cada post-it se ubica en un **día** dentro de un periodo: **Mañana / Tarde / Noche**.
- **Hover** → tarjetita con vista previa. **Clic** → abrir, ver detalle y registrar qué se hizo.
- **Registros** = trabajo real de los hoteles.
- Una ficha **con registro queda FIJA ✔** (post-it verde, no se mueve); las pendientes sí son arrastrables (post-it claro).
- **Fichas recurrentes**: diaria, semanal (anclada al día de la semana) y mensual.
- Campos extra por ficha: **hora** y **responsable**. Filtro/color por hotel.

## Fases
- **Fase 1:** tablero de post-its + fichas recurrentes + campos hora/responsable. ✅
- **Fase 2 (pendiente):** alertas de pendientes, panel de métricas, vista dedicada por hotel.

## Stack
- Frontend: HTML/JS estático (Supabase JS por CDN).
- Base de datos: **Supabase** (Auth, RLS).
- Despliegue: **Vercel** + repo **GitHub**.

---

## 1 · Configuración

### a) Migraciones de base (en orden)
Ve a **Supabase Dashboard → tu proyecto → SQL Editor → New query** y ejecuta en orden:
1. **`supabase/schema.sql`** (tablas base: `hoteles`, `fichas`, `registros` + RLS).
2. **`supabase/schema_v2.sql`** (recurrencia + `instancias`).

### b) Credenciales (sin exponerlas en GitHub)
El repo **no contiene** ninguna clave. Las credenciales se manejan así:
- **Local:** copia `js/env.example.js` a `js/env.js` (está en `.gitignore`, no se sube) y pega tu `url` + `anonKey`.
- **Vercel (deploy):** el build genera `js/env.js` automáticamente desde las variables de entorno **`SUPABASE_URL`** y **`SUPABASE_ANON_KEY`**. Configúralas en *Project Settings → Environment Variables*.

> ⚠️ **Seguridad:** la `anon key` de Supabase es pública por diseño y el frontend la necesita, pero **ya no se expone en GitHub**. La protección real de tus datos es el **RLS + login obligatorio**. Para invalidar una key que llegó a exponerse, rótala en *Supabase → Project Settings → API → Roll*.

---

## 2 · Cómo usar

| Acción | Cómo |
|--------|------|
| **Ver el mes** | Navega con ◀ ▶ y el botón **Hoy**. |
| **Crear ficha** | Botón **+ Nueva ficha**. Pon emoji, título, hotel, periodo, fecha y (opcional) recurrencia, hora y responsable. |
| **Ficha recurrente** | En el modal elige Diaria / Semanal / Mensual. Se reparte como post-its en los días que toca. |
| **Mover post-it** | Arrastra y suelta a otro día/periodo. **Las que ya están hechas no se mueven. ✔** |
| **Ver detalle** | Clic sobre el post-it → descripción, campos y registros. |
| **Registrar trabajo hecho** | En el detalle, escribe lo que hiciste y guarda. Ese **post-it queda verde/fijo**. |
| **Ocurrencias (recurrentes)** | En el detalle de una recurrente ves los días del mes; clic para navegar entre ocurrencias. |
| **Post-it vencido** | Los días pasados sin registrar se marcan como vencidos (post-it rojizo). |
| **Filtrar por hotel** | Usa los chips de hoteles arriba. |
| **Agregar hotel** | Clic en **+ Hotel**. |
| **Bandeja** | Fichas sin día asignado, para planificar después. |

## Estructura
```
organizate/
├── index.html                # Interfaz (login + calendario)
├── css/estilos.css           # Estilos
├── js/
│   ├── env.example.js        # Plantilla de credenciales
│   ├── env.js                # CREDENCIALES REALES (gitignoreado - NO subir; lo genera el build en Vercel)
│   ├── config.js             # Lector de credenciales (sin secretos)
│   └── app.js                # Lógica de la app
├── scripts/build-env.js      # Genera js/env.js desde vars de entorno (build)
├── supabase/
│   ├── schema.sql            # Tablas base
│   └── schema_v2.sql         # Recurrencia + instancias
└── vercel.json               # Config de build (Vercel)
```
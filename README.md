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
- **Fase 1.5 (actual):** acceso restringido con **sistema de usuarios (admin)** + backend en Vercel Functions. ✅
- **Fase 2 (pendiente):** alertas de pendientes, panel de métricas, vista dedicada por hotel.

## Stack
- Frontend: HTML/JS estático (Supabase JS por CDN).
- Base de datos: **Supabase** (Auth, RLS).
- Backend: **Vercel Functions** (`/api/usuarios`) que usa la `service_role key` (nunca expuesta al navegador).
- Despliegue: **Vercel** + repo **GitHub**.

---

## 1 · Configuración

### a) Migraciones de base (en orden)
Ve a **Supabase Dashboard → tu proyecto → SQL Editor → New query** y ejecuta en orden:
1. **`supabase/schema.sql`** (tablas base).
2. **`supabase/schema_v2.sql`** (recurrencia + `instancias`).
3. **`supabase/schema_v3.sql`** (tabla `perfiles` para roles).

### b) Acceso de usuarios (cerrado)
- **Desactiva el registro abierto**: Supabase → **Authentication → Providers → Email** → desmarca **"Allow new users to sign up"**.
- Para cada usuario (incluido tu admin), créalo en **Authentication → Users → Add user** (auto confirm ON): correo + contraseña.

### c) Crear tu usuario ADMIN
1. Crea tu usuario en Authentication → Users (p.ej. `tu@correo.com`).
2. Cópia su **UUID** de la lista de usuarios.
3. En SQL Editor ejecuta (reemplaza `TU_USER_UUID`):
   ```sql
   insert into public.perfiles (user_id, rol) values ('TU_USER_UUID', 'admin')
   on conflict (user_id) do update set rol = 'admin';
   ```
   Solo el admin ve y gestiona el botón **👥 Usuarios**.

### d) Variables de entorno en Vercel
Agrégalas en **Vercel → Dashboard → proyecto → Settings → Environment Variables** (para Production/Preview/Development):
- `SUPABASE_URL` = tu Project URL (ej. `https://xxxx.supabase.co`)
- `SUPABASE_ANON_KEY` = tu anon public key
- `SUPABASE_SERVICE_ROLE_KEY` = tu **service_role key** (⚠️ esta NO debe ir nunca al frontend ni al repo; solo la usa el backend)

> ⚠️ **Seguridad:** las credenciales reales van en `js/env.js` (gitignoreado) y en las variables de entorno de Vercel. **Nunca** pegues la `service_role key` en el repo. Las credenciales expuestas en el historial de git deben **rotarse** en Supabase (Settings → API → Roll).

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
| **Gestionar usuarios (solo admin)** | Botón **👥 Usuarios**: crear, resetear contraseña, activar/desactivar y eliminar usuarios. |

## Estructura
```
organizate/
├── index.html                # Interfaz (login + calendario + usuarios)
├── css/estilos.css           # Estilos
├── js/
│   ├── env.js                # CREDENCIALES REALES (gitignoreado - NO subir)
│   ├── env.example.js        # Plantilla de env.js
│   ├── config.js             # Lector de credenciales (sin secretos)
│   └── app.js                # Lógica de la app
├── api/
│   ├── package.json
│   └── usuarios.js           # Backend (Vercel Function) - gestión de usuarios
└── supabase/
    ├── schema.sql            # Tablas base
    ├── schema_v2.sql         # Recurrencia + instancias
    └── schema_v3.sql         # perfiles (roles)
```

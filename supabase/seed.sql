-- ============================================================
-- ORGANIZATE - SEED DATA
-- Ejecuta en: Supabase Dashboard -> SQL Editor -> New query
-- Copia y pega TODO este script, luego dale a "Run".
-- ============================================================

-- ============================================================
-- PARTE 1: Tablas (IF NOT EXISTS - seguro de re-ejecutar)
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- TABLA: hoteles
create table if not exists public.hoteles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  color text not null default '#3b82f6',
  created_at timestamptz not null default now()
);

-- TABLA: fichas
create table if not exists public.fichas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  hotel_id uuid references public.hoteles(id) on delete set null,
  emoji text,
  titulo text not null,
  descripcion text default '',
  periodo text not null default 'manana' check (periodo in ('manana','tarde','noche')),
  fecha date,
  fija boolean not null default false,
  orden integer not null default 0,
  recurrencia text not null default 'puntual'
    check (recurrencia in ('puntual','diaria','semanal','mensual')),
  dias_semana int[] default null,
  hora text default null,
  responsable text default null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- TABLA: registros
create table if not exists public.registros (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null default current_date,
  descripcion text default '',
  created_at timestamptz not null default now()
);

-- TABLA: instancias
create table if not exists public.instancias (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null,
  realizada boolean not null default true,
  created_at timestamptz not null default now(),
  unique (ficha_id, fecha)
);

-- Indices
create index if not exists idx_fichas_user      on public.fichas(user_id, fecha, periodo);
create index if not exists idx_fichas_hotel     on public.fichas(hotel_id);
create index if not exists idx_registros_ficha  on public.registros(ficha_id);
create index if not exists idx_instancias_ficha on public.instancias(ficha_id, fecha);

-- Trigger updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_fichas_updated on public.fichas;
create trigger trg_fichas_updated
  before update on public.fichas
  for each row execute function public.set_updated_at();

-- ============================================================
-- PARTE 2: RLS
-- ============================================================

alter table public.hoteles    enable row level security;
alter table public.fichas     enable row level security;
alter table public.registros  enable row level security;
alter table public.instancias enable row level security;

-- Eliminar policies existentes si las hay (para re-ejecutar limpio)
do $$
begin
  -- Hoteles
  drop policy if exists "hoteles own" on public.hoteles;
  create policy "hoteles own" on public.hoteles
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

  -- Fichas
  drop policy if exists "fichas own" on public.fichas;
  create policy "fichas own" on public.fichas
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

  -- Registros
  drop policy if exists "registros own" on public.registros;
  create policy "registros own" on public.registros
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

  -- Instancias
  drop policy if exists "instancias own" on public.instancias;
  create policy "instancias own" on public.instancias
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
end $$;

-- ============================================================
-- PARTE 3: Datos de ejemplo (solo si las tablas estan vacias)
-- ============================================================

-- Obtener el user_id del usuario actual
DO $$
DECLARE
  uid uuid := auth.uid();
  h_corales    uuid;
  h_latam      uuid;
  h_ghl        uuid;
  h_sonesta_ib uuid;
  h_sonesta_bu uuid;
BEGIN
  -- Solo insertar si no hay hoteles para este usuario
  IF EXISTS (SELECT 1 FROM public.hoteles WHERE user_id = uid) THEN
    RAISE NOTICE 'Ya existen hoteles para este usuario. Saltando seed.';
    RETURN;
  END IF;

  -- ---- HOTELES ----
  INSERT INTO public.hoteles (user_id, nombre, color) VALUES
    (uid, 'Corales',           '#ef4444') RETURNING id INTO h_corales;
  INSERT INTO public.hoteles (user_id, nombre, color) VALUES
    (uid, 'Latam Xela',        '#3b82f6') RETURNING id INTO h_latam;
  INSERT INTO public.hoteles (user_id, nombre, color) VALUES
    (uid, 'GHL Neiva',         '#10b981') RETURNING id INTO h_ghl;
  INSERT INTO public.hoteles (user_id, nombre, color) VALUES
    (uid, 'Sonesta Ibague',    '#f59e0b') RETURNING id INTO h_sonesta_ib;
  INSERT INTO public.hoteles (user_id, nombre, color) VALUES
    (uid, 'Sonesta Bucaramanga','#8b5cf6') RETURNING id INTO h_sonesta_bu;

  RAISE NOTICE 'Hoteles creados OK';

  -- ---- FICHAS: CORALES ----
  INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden) VALUES
    (uid, h_corales, '🔒', 'Revisión de candados',       'Verificar estado de todos los candados y cerraduras',        'manana', CURRENT_DATE, 'semanal', '08:00', 'Carlos M.', 1),
    (uid, h_corales, '🧯', 'Inspección de extintores',   'Revisar fecha de recarga y presión de cada extintor',       'manana', CURRENT_DATE, 'mensual', '09:00', 'Carlos M.', 2),
    (uid, h_corales, '💡', 'Cambio de luminarias',       'Revisar y reemplazar focos dañados en áreas comunes',       'tarde',  CURRENT_DATE + 3, 'puntual', '14:00', NULL, 1),
    (uid, h_corales, '📋', 'Inventario de amenities',    'Contar jabones, shampoo, toallas, etc.',                   'manana', CURRENT_DATE, 'semanal', '07:30', 'Ana L.', 3),
    (uid, h_corales, '🚿', 'Revisión de plomería',       'Verificar fugas en habitaciones 101-110',                  'manana', CURRENT_DATE, 'semanal', '10:00', 'Carlos M.', 4),
    (uid, h_corales, '🛏️', 'Cambio de ropa de cama',     'Rotación completa de sábanas y mantas',                    'manana', CURRENT_DATE, 'diaria',  '06:00', 'Equipo', 5);

  -- ---- FICHAS: LATAM XELA ----
  INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden) VALUES
    (uid, h_latam, '🌐', 'Prueba de WiFi',               'Test de velocidad en lobby, habitaciones y restaurante',   'manana', CURRENT_DATE, 'diaria',  '07:00', 'Técnico TI', 1),
    (uid, h_latam, '🖥️', 'Actualización de PMS',         'Aplicar parches del sistema de gestión hotelera',          'tarde',  CURRENT_DATE + 5, 'puntual', '15:00', 'Técnico TI', 1),
    (uid, h_latam, '📺', 'Calibración de TV',             'Ajustar canales y verificar señal en todas las TVs',      'manana', CURRENT_DATE, 'semanal', '09:00', 'Técnico TI', 2),
    (uid, h_latam, '🔒', 'Auditoría de accesos',          'Revisar logs de acceso y permisos del sistema',           'tarde',  CURRENT_DATE, 'semanal', '16:00', 'Técnico TI', 2),
    (uid, h_latam, '💾', 'Backup de bases de datos',       'Exportar y verificar integridad de backups',             'noche',  CURRENT_DATE, 'semanal', '22:00', 'Técnico TI', 3);

  -- ---- FICHAS: GHL NEIVA ----
  INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden) VALUES
    (uid, h_ghl, '🌡️', 'Revisión de A/C',               'Verificar termostatos y filtros de aire acondicionado',   'manana', CURRENT_DATE, 'semanal', '08:00', 'Mecánico', 1),
    (uid, h_ghl, '🧹', 'Limpieza profunda lobby',        'Aspirar, trapear, limpiar vitrales del lobby principal', 'manana', CURRENT_DATE + 1, 'puntual', '07:00', 'Equipo Limpieza', 1),
    (uid, h_ghl, '🔑', 'Auditoría de llaves master',      'Verificar que ninguna llave master esté extraviada',      'manana', CURRENT_DATE, 'mensual', '09:00', 'Recepción', 2),
    (uid, h_ghl, '📶', 'Configuración de routers',        'Actualizar firmware de routers del piso 2 y 3',          'tarde',  CURRENT_DATE + 2, 'puntual', '14:00', 'Técnico TI', 2),
    (uid, h_ghl, '🚿', 'Calentadores de agua',            'Revisar temperatura y presión de calentadores',          'manana', CURRENT_DATE, 'semanal', '08:30', 'Mecánico', 3);

  -- ---- FICHAS: SONESTA IBAGUE ----
  INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden) VALUES
    (uid, h_sonesta_ib, '🎯', 'Check-in de personal',       'Verificar asistencia y uniformes del equipo',            'manana', CURRENT_DATE, 'diaria',  '06:30', 'Gerente', 1),
    (uid, h_sonesta_ib, '📊', 'Reporte de ocupación',       'Generar reporte diario de habitaciones ocupadas',        'noche',  CURRENT_DATE, 'diaria',  '20:00', 'Recepción', 1),
    (uid, h_sonesta_ib, '🅿️', 'Revisión de parqueadero',    'Verificar señalización y estado del estacionamiento',    'manana', CURRENT_DATE, 'semanal', '07:00', 'Seguridad', 2),
    (uid, h_sonesta_ib, '🍳', 'Inspección de cocina',       'Revisar temperatura de refrigeradores y limpieza',       'manana', CURRENT_DATE, 'diaria',  '06:00', 'Chef', 2),
    (uid, h_sonesta_ib, '🚨', 'Simulacro de emergencia',    'Coordinar evacuación simulada con todo el personal',     'tarde',  CURRENT_DATE + 7, 'mensual', '15:00', 'Seguridad', 1);

  -- ---- FICHAS: SONESTA BUCARAMANGA ----
  INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden) VALUES
    (uid, h_sonesta_bu, '🏊', 'Mantenimiento piscina',      'Verificar pH, cloro y limpiar filtros de la piscina',    'manana', CURRENT_DATE, 'diaria',  '07:00', 'Auxiliar', 1),
    (uid, h_sonesta_bu, '🌳', 'Jardinería',                 'Podar césped, regar plantas y revisar iluminación',     'manana', CURRENT_DATE + 2, 'puntual', '08:00', 'Jardinero', 1),
    (uid, h_sonesta_bu, '🗑️', 'Recolección de basura',      'Supervisar separación de residuos y horarios',           'tarde',  CURRENT_DATE, 'diaria',  '17:00', 'Auxiliar', 2),
    (uid, h_sonesta_bu, '🏋️', 'Gimnasio - revisión',        'Verificar estado de máquinas y limpieza',                'manana', CURRENT_DATE, 'semanal', '08:00', 'Auxiliar', 2),
    (uid, h_sonesta_bu, '📶', 'Test de internet habitaciones', 'Probar velocidad en cada piso y reportar problemas',  'noche',  CURRENT_DATE, 'semanal', '21:00', 'Técnico TI', 3),
    (uid, h_sonesta_bu, '📋', 'Inventario de minibar',      'Contar productos y verificar fechas de vencimiento',    'manana', CURRENT_DATE, 'semanal', '09:00', 'Auxiliar', 3);

  RAISE NOTICE 'Fichas creadas OK - Total: 25 fichas de ejemplo';
END $$;

-- ============================================================
-- ORGANIZATE - SEED DATA (versión simplificada)
-- Ejecuta en: Supabase SQL Editor
-- Copia y pega TODO, luego dale "Run".
-- ============================================================

-- ============================================================
-- PARTE 1: Tablas (IF NOT EXISTS)
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

create table if not exists public.hoteles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  color text not null default '#3b82f6',
  created_at timestamptz not null default now()
);

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

create table if not exists public.registros (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null default current_date,
  descripcion text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.instancias (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null,
  realizada boolean not null default true,
  created_at timestamptz not null default now(),
  unique (ficha_id, fecha)
);

create index if not exists idx_fichas_user      on public.fichas(user_id, fecha, periodo);
create index if not exists idx_fichas_hotel     on public.fichas(hotel_id);
create index if not exists idx_registros_ficha  on public.registros(ficha_id);
create index if not exists idx_instancias_ficha on public.instancias(ficha_id, fecha);

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

drop policy if exists "hoteles own" on public.hoteles;
create policy "hoteles own" on public.hoteles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "fichas own" on public.fichas;
create policy "fichas own" on public.fichas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "registros own" on public.registros;
create policy "registros own" on public.registros
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "instancias own" on public.instancias;
create policy "instancias own" on public.instancias
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- PARTE 3: Obtener user_id por email
-- ============================================================

-- Crear variable temporal con el user_id
CREATE OR REPLACE FUNCTION public._tmp_get_uid()
RETURNS uuid LANGUAGE sql SECURITY DEFINER AS $$
  SELECT id FROM auth.users WHERE email = 'jean.galvis06@gmail.com' LIMIT 1;
$$;

-- ============================================================
-- PARTE 4: Hoteles
-- ============================================================

INSERT INTO public.hoteles (user_id, nombre, color)
SELECT public._tmp_get_uid(), 'Corales', '#ef4444'
WHERE NOT EXISTS (
  SELECT 1 FROM public.hoteles
  WHERE user_id = public._tmp_get_uid() AND nombre = 'Corales'
);

INSERT INTO public.hoteles (user_id, nombre, color)
SELECT public._tmp_get_uid(), 'Latam Xela', '#3b82f6'
WHERE NOT EXISTS (
  SELECT 1 FROM public.hoteles
  WHERE user_id = public._tmp_get_uid() AND nombre = 'Latam Xela'
);

INSERT INTO public.hoteles (user_id, nombre, color)
SELECT public._tmp_get_uid(), 'GHL Neiva', '#10b981'
WHERE NOT EXISTS (
  SELECT 1 FROM public.hoteles
  WHERE user_id = public._tmp_get_uid() AND nombre = 'GHL Neiva'
);

INSERT INTO public.hoteles (user_id, nombre, color)
SELECT public._tmp_get_uid(), 'Sonesta Ibague', '#f59e0b'
WHERE NOT EXISTS (
  SELECT 1 FROM public.hoteles
  WHERE user_id = public._tmp_get_uid() AND nombre = 'Sonesta Ibague'
);

INSERT INTO public.hoteles (user_id, nombre, color)
SELECT public._tmp_get_uid(), 'Sonesta Bucaramanga', '#8b5cf6'
WHERE NOT EXISTS (
  SELECT 1 FROM public.hoteles
  WHERE user_id = public._tmp_get_uid() AND nombre = 'Sonesta Bucaramanga'
);

-- ============================================================
-- PARTE 5: Fichas (usando subqueries para hotel_id)
-- ============================================================

-- CORALES
INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🔒', 'Revisión de candados', 'Verificar estado de todos los candados y cerraduras', 'manana', CURRENT_DATE, 'semanal', '08:00', 'Carlos M.', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Revisión de candados' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🧯', 'Inspección de extintores', 'Revisar fecha de recarga y presión de cada extintor', 'manana', CURRENT_DATE, 'mensual', '09:00', 'Carlos M.', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Inspección de extintores' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '💡', 'Cambio de luminarias', 'Revisar y reemplazar focos dañados en áreas comunes', 'tarde', CURRENT_DATE + 3, 'puntual', '14:00', NULL, 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Cambio de luminarias' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📋', 'Inventario de amenities', 'Contar jabones, shampoo, toallas, etc.', 'manana', CURRENT_DATE, 'semanal', '07:30', 'Ana L.', 3
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Inventario de amenities' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🚿', 'Revisión de plomería', 'Verificar fugas en habitaciones 101-110', 'manana', CURRENT_DATE, 'semanal', '10:00', 'Carlos M.', 4
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Revisión de plomería' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🛏️', 'Cambio de ropa de cama', 'Rotación completa de sábanas y mantas', 'manana', CURRENT_DATE, 'diaria', '06:00', 'Equipo', 5
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Corales'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Cambio de ropa de cama' AND f.hotel_id = h.id);

-- LATAM XELA
INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🌐', 'Prueba de WiFi', 'Test de velocidad en lobby, habitaciones y restaurante', 'manana', CURRENT_DATE, 'diaria', '07:00', 'Técnico TI', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Latam Xela'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Prueba de WiFi' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🖥️', 'Actualización de PMS', 'Aplicar parches del sistema de gestión hotelera', 'tarde', CURRENT_DATE + 5, 'puntual', '15:00', 'Técnico TI', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Latam Xela'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Actualización de PMS' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📺', 'Calibración de TV', 'Ajustar canales y verificar señal en todas las TVs', 'manana', CURRENT_DATE, 'semanal', '09:00', 'Técnico TI', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Latam Xela'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Calibración de TV' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🔒', 'Auditoría de accesos', 'Revisar logs de acceso y permisos del sistema', 'tarde', CURRENT_DATE, 'semanal', '16:00', 'Técnico TI', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Latam Xela'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Auditoría de accesos' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '💾', 'Backup de bases de datos', 'Exportar y verificar integridad de backups', 'noche', CURRENT_DATE, 'semanal', '22:00', 'Técnico TI', 3
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Latam Xela'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Backup de bases de datos' AND f.hotel_id = h.id);

-- GHL NEIVA
INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🌡️', 'Revisión de A/C', 'Verificar termostatos y filtros de aire acondicionado', 'manana', CURRENT_DATE, 'semanal', '08:00', 'Mecánico', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'GHL Neiva'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Revisión de A/C' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🧹', 'Limpieza profunda lobby', 'Aspirar, trapear, limpiar vitrales del lobby principal', 'manana', CURRENT_DATE + 1, 'puntual', '07:00', 'Equipo Limpieza', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'GHL Neiva'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Limpieza profunda lobby' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🔑', 'Auditoría de llaves master', 'Verificar que ninguna llave master esté extraviada', 'manana', CURRENT_DATE, 'mensual', '09:00', 'Recepción', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'GHL Neiva'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Auditoría de llaves master' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📶', 'Configuración de routers', 'Actualizar firmware de routers del piso 2 y 3', 'tarde', CURRENT_DATE + 2, 'puntual', '14:00', 'Técnico TI', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'GHL Neiva'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Configuración de routers' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🚿', 'Calentadores de agua', 'Revisar temperatura y presión de calentadores', 'manana', CURRENT_DATE, 'semanal', '08:30', 'Mecánico', 3
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'GHL Neiva'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Calentadores de agua' AND f.hotel_id = h.id);

-- SONESTA IBAGUE
INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🎯', 'Check-in de personal', 'Verificar asistencia y uniformes del equipo', 'manana', CURRENT_DATE, 'diaria', '06:30', 'Gerente', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Ibague'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Check-in de personal' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📊', 'Reporte de ocupación', 'Generar reporte diario de habitaciones ocupadas', 'noche', CURRENT_DATE, 'diaria', '20:00', 'Recepción', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Ibague'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Reporte de ocupación' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🅿️', 'Revisión de parqueadero', 'Verificar señalización y estado del estacionamiento', 'manana', CURRENT_DATE, 'semanal', '07:00', 'Seguridad', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Ibague'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Revisión de parqueadero' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🍳', 'Inspección de cocina', 'Revisar temperatura de refrigeradores y limpieza', 'manana', CURRENT_DATE, 'diaria', '06:00', 'Chef', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Ibague'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Inspección de cocina' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🚨', 'Simulacro de emergencia', 'Coordinar evacuación simulada con todo el personal', 'tarde', CURRENT_DATE + 7, 'mensual', '15:00', 'Seguridad', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Ibague'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Simulacro de emergencia' AND f.hotel_id = h.id);

-- SONESTA BUCARAMANGA
INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🏊', 'Mantenimiento piscina', 'Verificar pH, cloro y limpiar filtros de la piscina', 'manana', CURRENT_DATE, 'diaria', '07:00', 'Auxiliar', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Mantenimiento piscina' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🌳', 'Jardinería', 'Podar césped, regar plantas y revisar iluminación', 'manana', CURRENT_DATE + 2, 'puntual', '08:00', 'Jardinero', 1
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Jardinería' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🗑️', 'Recolección de basura', 'Supervisar separación de residuos y horarios', 'tarde', CURRENT_DATE, 'diaria', '17:00', 'Auxiliar', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Recolección de basura' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '🏋️', 'Gimnasio - revisión', 'Verificar estado de máquinas y limpieza', 'manana', CURRENT_DATE, 'semanal', '08:00', 'Auxiliar', 2
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Gimnasio - revisión' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📶', 'Test de internet habitaciones', 'Probar velocidad en cada piso y reportar problemas', 'noche', CURRENT_DATE, 'semanal', '21:00', 'Técnico TI', 3
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Test de internet habitaciones' AND f.hotel_id = h.id);

INSERT INTO public.fichas (user_id, hotel_id, emoji, titulo, descripcion, periodo, fecha, recurrencia, hora, responsable, orden)
SELECT public._tmp_get_uid(), h.id, '📋', 'Inventario de minibar', 'Contar productos y verificar fechas de vencimiento', 'manana', CURRENT_DATE, 'semanal', '09:00', 'Auxiliar', 3
FROM public.hoteles h WHERE h.user_id = public._tmp_get_uid() AND h.nombre = 'Sonesta Bucaramanga'
AND NOT EXISTS (SELECT 1 FROM public.fichas f WHERE f.user_id = public._tmp_get_uid() AND f.titulo = 'Inventario de minibar' AND f.hotel_id = h.id);

-- ============================================================
-- LIMPIAR: eliminar la función auxiliar temporal
-- ============================================================
DROP FUNCTION IF EXISTS public._tmp_get_uid();

-- ============================================================
-- ORGANIZATE - Esquema de Supabase
-- Ejecuta esto en: Supabase Dashboard -> SQL Editor -> New query
-- IMPORTANTE: Habilitar RLS (Row Level Security) con la opcion de
-- "algun dia podria necesitarlo" / forzar RLS.
-- ============================================================

-- Extensiones necesarias (normalmente ya vienen activadas)
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ---- TABLA: hoteles -------------------------------------------------
create table if not exists public.hoteles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  color text not null default '#3b82f6',
  created_at timestamptz not null default now()
);

-- ---- TABLA: fichas (actividades) ------------------------------------
-- Representa una actividad recurrente o puntual.
create table if not exists public.fichas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  hotel_id uuid references public.hoteles(id) on delete set null,
  emoji text,
  titulo text not null,
  descripcion text default '',
  -- Periodo del dia: 'manana' | 'tarde' | 'noche'
  periodo text not null default 'manana' check (periodo in ('manana','tarde','noche')),
  -- Dia objetivo en el mes (YYYY-MM-DD) o null si es sin fecha (bandeja)
  fecha date,
  -- Si true: la ficha esta bloqueada (tiene registro de trabajo hecho)
  fija boolean not null default false,
  -- Orden relativo dentro del mismo dia+periodo
  orden integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---- TABLA: registros (trabajo real hecho) ---------------------------
-- Cada vez que el usuario hace la actividad, guarda un registro.
-- La existencia de al menos un registro pone la ficha en "fija".
create table if not exists public.registros (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null default current_date,
  descripcion text default '',
  created_at timestamptz not null default now()
);

-- ---- Indices ----------------------------------------------------------
create index if not exists idx_fichas_user   on public.fichas(user_id, fecha, periodo);
create index if not exists idx_fichas_hotel  on public.fichas(hotel_id);
create index if not exists idx_registros_ficha on public.registros(ficha_id);

-- ---- Funcion para actualizar updated_at -------------------------------
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
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.hoteles   enable row level security;
alter table public.fichas    enable row level security;
alter table public.registros enable row level security;

-- Usuarios solo ven sus propios datos
create policy "hoteles own"   on public.hoteles   for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "fichas own"    on public.fichas    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "registros own" on public.registros for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

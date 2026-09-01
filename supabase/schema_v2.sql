-- ============================================================
-- ORGANIZATE - MIGRACION v2 (Fase 1)
-- Ejecuta en Supabase SQL Editor. Es ADITIVA: no borra nada.
-- Añade recurrencia + instancias.
-- ============================================================

-- ---- Nuevas columnas en fichas ----------------------------------
alter table public.fichas add column if not exists recurrencia text not null default 'puntual'
  check (recurrencia in ('puntual','diaria','semanal','mensual'));

-- dias_semana: array de numeros 0-6 (0=Domingo ... 6=Sabado) para recurrencia semanal
alter table public.fichas add column if not exists dias_semana int[] default null;

-- hora (formato HH:MM) y responsable (opcional)
alter table public.fichas add column if not exists hora text default null;
alter table public.fichas add column if not exists responsable text default null;

-- ---- Tabla: instancias -------------------------------------------
-- Cada vez que una ficha recurrente se realiza/marca en un dia concreto,
-- se crea una instancia. La fecha de la instancia determina el "posit" fijo.
create table if not exists public.instancias (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  fecha date not null,
  realizada boolean not null default true,
  created_at timestamptz not null default now(),
  unique (ficha_id, fecha)
);

create index if not exists idx_instancias_ficha on public.instancias(ficha_id, fecha);

-- ---- RLS para instancias ------------------------------------------
alter table public.instancias enable row level security;
create policy "instancias own" on public.instancias
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

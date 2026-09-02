-- ============================================================
-- ORGANIZATE - MIGRACION: Recurrencia "semana del mes"
-- Ejecuta en: Supabase SQL Editor
-- ============================================================

-- Nueva opción de recurrencia
ALTER TABLE public.fichas DROP CONSTRAINT IF EXISTS fichas_recurrencia_check;
ALTER TABLE public.fichas ADD CONSTRAINT fichas_recurrencia_check
  CHECK (recurrencia IN ('puntual','diaria','semanal','mensual','semana_del_mes'));

-- Columnas para "semana del mes": ej. 3er miércoles
-- dia_semana: 0=Domingo ... 6=Sábado
ALTER TABLE public.fichas ADD COLUMN IF NOT EXISTS dia_semana integer DEFAULT NULL;
-- semana_del_mes: 1=primera, 2=segunda, 3=tercera, 4=cuarta, 5=quinta
ALTER TABLE public.fichas ADD COLUMN IF NOT EXISTS semana_del_mes integer DEFAULT NULL;

-- Verificar
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'fichas' AND column_name IN ('dia_semana', 'semana_del_mes', 'recurrencia')
ORDER BY column_name;

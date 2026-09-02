-- ============================================================
-- ORGANIZATE - LIMPIAR DATOS DE EJEMPLO
-- Ejecuta en: Supabase SQL Editor
-- Esto elimina todos los hoteles y fichas, pero mantiene las tablas.
-- ============================================================

-- Eliminar en orden correcto (por foreign keys)
DELETE FROM public.instancias;
DELETE FROM public.registros;
DELETE FROM public.fichas;
DELETE FROM public.hoteles;

-- Eliminar función auxiliar si quedó
DROP FUNCTION IF EXISTS public._tmp_get_uid();

-- Verificar que quedó vacío
SELECT
  (SELECT COUNT(*) FROM public.hoteles) as hoteles,
  (SELECT COUNT(*) FROM public.fichas) as fichas,
  (SELECT COUNT(*) FROM public.registros) as registros,
  (SELECT COUNT(*) FROM public.instancias) as instancias;

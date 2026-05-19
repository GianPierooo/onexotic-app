-- Campos de recurrencia para la tabla reuniones.
-- Ejecutar en Supabase Dashboard → SQL Editor.

ALTER TABLE public.reuniones
  ADD COLUMN IF NOT EXISTS recurrencia         text    NOT NULL DEFAULT 'ninguna'
    CHECK (recurrencia IN ('ninguna','diaria','semanal','laboral','personalizado')),
  ADD COLUMN IF NOT EXISTS recurrencia_grupo_id uuid,
  ADD COLUMN IF NOT EXISTS recurrencia_dias     int[]   DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS recurrencia_fin      date    DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_reuniones_grupo
  ON public.reuniones (recurrencia_grupo_id)
  WHERE recurrencia_grupo_id IS NOT NULL;

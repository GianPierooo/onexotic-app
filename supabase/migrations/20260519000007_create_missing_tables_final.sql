-- ============================================================
-- MIGRACIÓN FINAL: consolida todas las tablas y políticas
-- que pueden no haberse aplicado aún.
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Tabla disenio_historial ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.disenio_historial (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disenio_id  uuid NOT NULL REFERENCES public.disenios(id) ON DELETE CASCADE,
  accion      text NOT NULL,
  descripcion text,
  usuario_id  uuid REFERENCES auth.users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_disenio_historial_disenio
  ON public.disenio_historial (disenio_id);

ALTER TABLE public.disenio_historial ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "auth_read_historial"   ON public.disenio_historial;
DROP POLICY IF EXISTS "auth_insert_historial" ON public.disenio_historial;

CREATE POLICY "auth_read_historial" ON public.disenio_historial
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_insert_historial" ON public.disenio_historial
  FOR INSERT TO authenticated WITH CHECK (true);

-- ── 2. Tabla disenio_avances ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.disenio_avances (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disenio_id  uuid NOT NULL REFERENCES public.disenios(id) ON DELETE CASCADE,
  imagen_url  text NOT NULL,
  nota        text,
  subido_por  uuid REFERENCES auth.users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_disenio_avances_disenio
  ON public.disenio_avances (disenio_id);

ALTER TABLE public.disenio_avances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "auth_read_avances"   ON public.disenio_avances;
DROP POLICY IF EXISTS "auth_insert_avances" ON public.disenio_avances;

CREATE POLICY "auth_read_avances" ON public.disenio_avances
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_insert_avances" ON public.disenio_avances
  FOR INSERT TO authenticated WITH CHECK (true);

-- ── 3. RLS tabla disenio_historial (por si disenio_id column falta) ──────────
ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS disenio_id uuid
  REFERENCES public.disenios(id) ON DELETE SET NULL;

-- ── 4. Fix RLS en tabla briefs ────────────────────────────────────────────────
-- Permite a diseñadoras crear briefs para sus propios diseños.
DROP POLICY IF EXISTS "disenadora_insertar_brief"  ON public.briefs;
DROP POLICY IF EXISTS "disenadora_actualizar_brief" ON public.briefs;

CREATE POLICY "disenadora_insertar_brief" ON public.briefs
  FOR INSERT TO authenticated
  WITH CHECK (
    creado_por = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.disenios d
      WHERE d.id = disenio_id
        AND d.disenadora_id = auth.uid()
    )
  );

CREATE POLICY "disenadora_actualizar_brief" ON public.briefs
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.disenios d
      WHERE d.id = disenio_id
        AND d.disenadora_id = auth.uid()
    )
  );

-- Política más simple como fallback (authenticated puede crear si cumple check)
DROP POLICY IF EXISTS "Crear briefs" ON public.briefs;
DROP POLICY IF EXISTS "Ver briefs"   ON public.briefs;

CREATE POLICY "Crear briefs" ON public.briefs
  FOR INSERT TO authenticated
  WITH CHECK (creado_por = auth.uid());

CREATE POLICY "Ver briefs" ON public.briefs
  FOR SELECT TO authenticated
  USING (true);

-- ── 5. Fix CHECK constraint de estados en disenios ────────────────────────────
ALTER TABLE public.disenios
  DROP CONSTRAINT IF EXISTS disenios_estado_check;

ALTER TABLE public.disenios
  ADD CONSTRAINT disenios_estado_check
  CHECK (estado IN (
    'brief', 'proceso', 'avance', 'revision',
    'aprobado', 'rechazado', 'cancelado'
  ));

-- Tarea 1: historial de diseños + disenio_id en productos
-- Ejecutar en Supabase Dashboard → SQL Editor antes de usar
-- el flujo "Crear en inventario" desde un diseño aprobado.

-- ── Tabla disenio_historial ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.disenio_historial (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disenio_id  uuid NOT NULL REFERENCES public.disenios(id) ON DELETE CASCADE,
  accion      text NOT NULL,
  descripcion text,
  usuario_id  uuid REFERENCES public.users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_disenio_historial_disenio
  ON public.disenio_historial (disenio_id);

ALTER TABLE public.disenio_historial ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth_read_historial" ON public.disenio_historial
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "auth_insert_historial" ON public.disenio_historial
  FOR INSERT TO authenticated WITH CHECK (true);

-- ── Columna disenio_id en productos ───────────────────────────────────────────
ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS disenio_id uuid
  REFERENCES public.disenios(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_productos_disenio
  ON public.productos (disenio_id);

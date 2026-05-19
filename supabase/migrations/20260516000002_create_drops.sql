-- Tabla: drops
-- Sistema de drops limitados de OnExotic

CREATE TABLE public.drops (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre             text NOT NULL,
  concepto           text,
  fecha_lanzamiento  date,
  estado             text NOT NULL DEFAULT 'planificacion'
                     CHECK (estado IN ('planificacion', 'produccion', 'lanzado', 'agotado')),
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_drops_estado ON public.drops (estado);
CREATE INDEX idx_drops_fecha ON public.drops (fecha_lanzamiento);

-- RLS
ALTER TABLE public.drops ENABLE ROW LEVEL SECURITY;

-- Todos los usuarios autenticados pueden ver drops
CREATE POLICY "todos_ver_drops" ON public.drops
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Solo CEO y Manager pueden insertar/actualizar/eliminar drops
CREATE POLICY "ceo_manager_crud_drops" ON public.drops
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

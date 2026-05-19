-- Tabla: briefs
-- Briefings creativos para disenios

CREATE TABLE public.briefs (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  disenio_id          uuid NOT NULL REFERENCES public.disenios(id) ON DELETE CASCADE,
  titulo              text NOT NULL,
  descripcion         text,
  referencias_urls    text[] DEFAULT '{}',
  colores             text[] DEFAULT '{}',
  tipografia          text,
  notas_adicionales   text,
  fecha_limite        date,
  creado_por          uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_briefs_disenio ON public.briefs (disenio_id);
CREATE INDEX idx_briefs_creado_por ON public.briefs (creado_por);

-- RLS
ALTER TABLE public.briefs ENABLE ROW LEVEL SECURITY;

-- CEO ve todos los briefs
CREATE POLICY "ceo_ver_todos_briefs" ON public.briefs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

-- Disenadora ve los briefs de sus disenios
CREATE POLICY "disenadora_ver_propios_briefs" ON public.briefs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.disenios d
      WHERE d.id = disenio_id
        AND d.disenadora_id = auth.uid()
    )
  );

-- CEO puede hacer CRUD completo en briefs
CREATE POLICY "ceo_crud_briefs" ON public.briefs
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

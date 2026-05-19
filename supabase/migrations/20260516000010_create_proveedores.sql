-- Tabla: proveedores
-- Registro de proveedores (telas, estampado, confeccion, packaging)

CREATE TABLE public.proveedores (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      text NOT NULL,
  contacto    text,
  telefono    text,
  tipo        text CHECK (tipo IN ('tela', 'estampado', 'confeccion', 'packaging')),
  rating      integer CHECK (rating BETWEEN 1 AND 5),
  notas       text,
  activo      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_proveedores_tipo ON public.proveedores (tipo);
CREATE INDEX idx_proveedores_activo ON public.proveedores (activo);

-- RLS
ALTER TABLE public.proveedores ENABLE ROW LEVEL SECURITY;

-- CEO y Produccion ven todos los proveedores
CREATE POLICY "ceo_produccion_ver_proveedores" ON public.proveedores
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'produccion')
    )
  );

-- CEO puede CRUD completo en proveedores
CREATE POLICY "ceo_crud_proveedores" ON public.proveedores
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

-- Produccion puede actualizar proveedores (rating, notas)
CREATE POLICY "produccion_actualizar_proveedores" ON public.proveedores
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'produccion'
    )
  );

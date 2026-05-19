-- Tabla: disenios
-- Gestion del flujo de diseños: brief -> proceso -> revision -> aprobado/rechazado

CREATE TABLE public.disenios (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo         text NOT NULL,
  drop_id        uuid REFERENCES public.drops(id) ON DELETE SET NULL,
  disenadora_id  uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  estado         text NOT NULL DEFAULT 'brief'
                 CHECK (estado IN ('brief', 'proceso', 'revision', 'aprobado', 'rechazado')),
  archivo_url    text,
  thumbnail_url  text,
  aprobado_por   uuid REFERENCES public.users(id) ON DELETE SET NULL,
  fecha_limite   date,
  feedback       text,
  version        integer NOT NULL DEFAULT 1,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_disenios_disenadora ON public.disenios (disenadora_id);
CREATE INDEX idx_disenios_drop ON public.disenios (drop_id);
CREATE INDEX idx_disenios_estado ON public.disenios (estado);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER disenios_updated_at
  BEFORE UPDATE ON public.disenios
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE public.disenios ENABLE ROW LEVEL SECURITY;

-- CEO ve todos los disenios
CREATE POLICY "ceo_ver_todos_disenios" ON public.disenios
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

-- Disenadora ve solo sus propios disenios
CREATE POLICY "disenadora_ver_propios" ON public.disenios
  FOR SELECT USING (
    disenadora_id = auth.uid()
  );

-- Produccion ve solo disenios aprobados
CREATE POLICY "produccion_ver_aprobados" ON public.disenios
  FOR SELECT USING (
    estado = 'aprobado'
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'produccion'
    )
  );

-- CEO puede hacer CRUD completo
CREATE POLICY "ceo_crud_disenios" ON public.disenios
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

-- Disenadora puede insertar sus propios disenios
CREATE POLICY "disenadora_insertar_propios" ON public.disenios
  FOR INSERT WITH CHECK (
    disenadora_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'disenadora'
    )
  );

-- Disenadora puede actualizar sus propios disenios (no puede aprobar)
CREATE POLICY "disenadora_actualizar_propios" ON public.disenios
  FOR UPDATE USING (
    disenadora_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'disenadora'
    )
  )
  WITH CHECK (
    disenadora_id = auth.uid()
    AND estado NOT IN ('aprobado')
  );

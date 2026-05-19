-- Tabla: bonos
-- Registro de bonos aprobados por el equipo

CREATE TABLE public.bonos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  monto         decimal(10, 2) NOT NULL,
  motivo        text NOT NULL,
  periodo       text NOT NULL,
  aprobado_por  uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_bonos_user ON public.bonos (user_id);
CREATE INDEX idx_bonos_periodo ON public.bonos (periodo);

-- RLS
ALTER TABLE public.bonos ENABLE ROW LEVEL SECURITY;

-- CEO y RRHH ven todos los bonos
CREATE POLICY "ceo_rrhh_ver_todos_bonos" ON public.bonos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'rrhh')
    )
  );

-- Cada usuario puede ver sus propios bonos
CREATE POLICY "usuario_ver_propios_bonos" ON public.bonos
  FOR SELECT USING (user_id = auth.uid());

-- CEO y RRHH pueden crear bonos
CREATE POLICY "ceo_rrhh_crear_bonos" ON public.bonos
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'rrhh')
    )
  );

-- CEO puede actualizar y eliminar bonos
CREATE POLICY "ceo_actualizar_eliminar_bonos" ON public.bonos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
    )
  );

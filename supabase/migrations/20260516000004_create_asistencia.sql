-- Tabla: asistencia
-- Registro de asistencia a reuniones del equipo

CREATE TABLE public.asistencia (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  fecha         date NOT NULL,
  presente      boolean NOT NULL DEFAULT false,
  hora_entrada  timestamptz,
  nota          text,
  reunion_tipo  text NOT NULL DEFAULT 'diaria'
                CHECK (reunion_tipo IN ('diaria', 'semanal', 'extraordinaria')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, fecha, reunion_tipo)
);

-- Indices
CREATE INDEX idx_asistencia_user ON public.asistencia (user_id);
CREATE INDEX idx_asistencia_fecha ON public.asistencia (fecha);
CREATE INDEX idx_asistencia_fecha_tipo ON public.asistencia (fecha, reunion_tipo);

-- RLS
ALTER TABLE public.asistencia ENABLE ROW LEVEL SECURITY;

-- CEO, Manager y RRHH ven toda la asistencia
CREATE POLICY "ceo_manager_rrhh_ver_asistencia" ON public.asistencia
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'rrhh')
    )
  );

-- Disenadora y Produccion solo ven su propia asistencia
CREATE POLICY "usuario_ver_propia_asistencia" ON public.asistencia
  FOR SELECT USING (user_id = auth.uid());

-- CEO y RRHH pueden insertar asistencia de cualquier usuario
CREATE POLICY "ceo_rrhh_insertar_asistencia" ON public.asistencia
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'rrhh')
    )
  );

-- Cada usuario puede insertar su propia asistencia
CREATE POLICY "usuario_insertar_propia_asistencia" ON public.asistencia
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- CEO y RRHH pueden actualizar cualquier asistencia
CREATE POLICY "ceo_rrhh_actualizar_asistencia" ON public.asistencia
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'rrhh')
    )
  );

-- Solo CEO puede eliminar registros de asistencia
CREATE POLICY "ceo_eliminar_asistencia" ON public.asistencia
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
    )
  );

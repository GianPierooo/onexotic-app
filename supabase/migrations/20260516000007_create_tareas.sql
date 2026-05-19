-- Tabla: tareas
-- Gestion de tareas del equipo por area y prioridad

CREATE TABLE public.tareas (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo       text NOT NULL,
  descripcion  text,
  area         text NOT NULL CHECK (area IN ('tech', 'disenio', 'marketing', 'produccion', 'rrhh', 'legal')),
  prioridad    text NOT NULL DEFAULT 'media' CHECK (prioridad IN ('alta', 'media', 'baja')),
  asignado_a   uuid REFERENCES public.users(id) ON DELETE SET NULL,
  completado   boolean NOT NULL DEFAULT false,
  fecha_limite date,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_tareas_asignado ON public.tareas (asignado_a);
CREATE INDEX idx_tareas_completado ON public.tareas (completado);
CREATE INDEX idx_tareas_prioridad ON public.tareas (prioridad);
CREATE INDEX idx_tareas_area ON public.tareas (area);

-- Trigger updated_at
CREATE TRIGGER tareas_updated_at
  BEFORE UPDATE ON public.tareas
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE public.tareas ENABLE ROW LEVEL SECURITY;

-- CEO y Manager ven todas las tareas
CREATE POLICY "ceo_manager_ver_todas_tareas" ON public.tareas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

-- RRHH ve todas las tareas
CREATE POLICY "rrhh_ver_todas_tareas" ON public.tareas
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'rrhh'
    )
  );

-- Disenadora y Produccion solo ven sus propias tareas
CREATE POLICY "usuario_ver_propias_tareas" ON public.tareas
  FOR SELECT USING (asignado_a = auth.uid());

-- CEO y Manager pueden crear tareas
CREATE POLICY "ceo_manager_crear_tareas" ON public.tareas
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

-- CEO y Manager pueden actualizar cualquier tarea
CREATE POLICY "ceo_manager_actualizar_tareas" ON public.tareas
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager')
    )
  );

-- RRHH puede actualizar estado de tareas
CREATE POLICY "rrhh_actualizar_tareas" ON public.tareas
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'rrhh'
    )
  );

-- Cada usuario puede marcar sus propias tareas como completadas
CREATE POLICY "usuario_completar_propia_tarea" ON public.tareas
  FOR UPDATE USING (asignado_a = auth.uid())
  WITH CHECK (asignado_a = auth.uid());

-- Solo CEO puede eliminar tareas
CREATE POLICY "ceo_eliminar_tareas" ON public.tareas
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
    )
  );

-- Tabla: notificaciones
-- Notificaciones internas del sistema para cada usuario

CREATE TABLE public.notificaciones (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  titulo      text NOT NULL,
  mensaje     text,
  tipo        text NOT NULL CHECK (tipo IN ('asistencia', 'disenio', 'tarea', 'inventario', 'bono', 'sistema')),
  leido       boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_notificaciones_user ON public.notificaciones (user_id);
CREATE INDEX idx_notificaciones_leido ON public.notificaciones (user_id, leido);
CREATE INDEX idx_notificaciones_created ON public.notificaciones (created_at DESC);

-- RLS
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;

-- Cada usuario solo ve sus propias notificaciones
CREATE POLICY "usuario_ver_propias_notificaciones" ON public.notificaciones
  FOR SELECT USING (user_id = auth.uid());

-- El sistema (service_role) puede insertar notificaciones para cualquier usuario
-- Los usuarios autenticados pueden insertar notificaciones (para triggers)
CREATE POLICY "insertar_notificaciones" ON public.notificaciones
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Cada usuario puede marcar sus propias notificaciones como leidas
CREATE POLICY "usuario_actualizar_propias_notificaciones" ON public.notificaciones
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Cada usuario puede eliminar sus propias notificaciones
CREATE POLICY "usuario_eliminar_propias_notificaciones" ON public.notificaciones
  FOR DELETE USING (user_id = auth.uid());

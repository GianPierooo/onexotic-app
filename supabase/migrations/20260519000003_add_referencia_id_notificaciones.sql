-- Agrega referencia_id a notificaciones (referencia opcional al objeto relacionado)
-- La app Flutter lee esta columna en Notificacion.fromJson

ALTER TABLE public.notificaciones
  ADD COLUMN IF NOT EXISTS referencia_id uuid;

-- Habilitar Realtime para badge en tiempo real del dashboard
ALTER PUBLICATION supabase_realtime ADD TABLE public.notificaciones;

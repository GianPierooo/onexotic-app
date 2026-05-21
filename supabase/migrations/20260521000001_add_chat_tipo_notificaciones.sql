-- Agrega 'chat' al CHECK constraint de notificaciones.tipo
-- Sin esto, los inserts hechos por chat_provider.dart fallan con
-- 23514 (check_violation) y el push de mensajes de chat nunca persiste.

ALTER TABLE public.notificaciones
  DROP CONSTRAINT IF EXISTS notificaciones_tipo_check,
  ADD CONSTRAINT notificaciones_tipo_check
    CHECK (tipo IN ('asistencia','disenio','tarea','inventario','bono','sistema','chat'));

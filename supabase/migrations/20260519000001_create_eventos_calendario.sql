-- Tabla de eventos del calendario (eventos manuales editables)
-- Fuentes de datos fusionadas: drops, asistencia, tareas, diseños
-- Esta tabla almacena SOLO los eventos creados manualmente por el equipo

CREATE TABLE IF NOT EXISTS public.eventos_calendario (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo         text        NOT NULL,   -- 'Reunión de equipo'|'Lanzamiento de drop'|etc.
  titulo       text        NOT NULL,
  fecha        date        NOT NULL,
  hora         text,                   -- '09:00:00' — guardado como text para evitar timezone issues
  lugar        text,
  descripcion  text,
  color        text        DEFAULT '#FF4500',
  creado_por   uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   timestamptz DEFAULT now()
);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.eventos_calendario ENABLE ROW LEVEL SECURITY;

-- Todos los autenticados ven todos los eventos del equipo
CREATE POLICY "eventos_select_authenticated"
  ON public.eventos_calendario
  FOR SELECT
  TO authenticated
  USING (true);

-- Cualquier autenticado puede crear eventos
CREATE POLICY "eventos_insert_authenticated"
  ON public.eventos_calendario
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

-- Solo el creador puede editar sus eventos
CREATE POLICY "eventos_update_own"
  ON public.eventos_calendario
  FOR UPDATE
  TO authenticated
  USING (creado_por = auth.uid())
  WITH CHECK (creado_por = auth.uid());

-- Solo el creador puede eliminar sus eventos
CREATE POLICY "eventos_delete_own"
  ON public.eventos_calendario
  FOR DELETE
  TO authenticated
  USING (creado_por = auth.uid());

-- ─── Realtime (opcional — para que se actualice sin recargar) ─────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.eventos_calendario;

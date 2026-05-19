-- Tabla para registrar qué guías de onboarding ya vio cada usuario
-- Evita que la guía se muestre más de una vez por módulo

CREATE TABLE IF NOT EXISTS public.guias_vistas (
  id       uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  modulo   text        NOT NULL,
  vista_at timestamptz DEFAULT now(),
  UNIQUE (user_id, modulo)
);

ALTER TABLE public.guias_vistas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "guias_all_own"
  ON public.guias_vistas
  FOR ALL
  TO authenticated
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Fix 1: Diseñadora puede insertar briefs para sus propios diseños.
-- Sin esta política, el INSERT a briefs fallaba silenciosamente.
CREATE POLICY "disenadora_insertar_brief" ON public.briefs
  FOR INSERT
  WITH CHECK (
    creado_por = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.disenios d
      WHERE d.id = disenio_id
        AND d.disenadora_id = auth.uid()
    )
  );

-- Fix 2: Diseñadora puede actualizar el brief de su propio diseño.
CREATE POLICY "disenadora_actualizar_brief" ON public.briefs
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.disenios d
      WHERE d.id = disenio_id
        AND d.disenadora_id = auth.uid()
    )
  );

-- Fix 3: Añadir estados 'avance' y 'cancelado' al CHECK constraint de disenios.
-- El código usa estos estados pero la migración original no los incluía.
ALTER TABLE public.disenios
  DROP CONSTRAINT IF EXISTS disenios_estado_check;

ALTER TABLE public.disenios
  ADD CONSTRAINT disenios_estado_check
  CHECK (estado IN (
    'brief', 'proceso', 'avance', 'revision',
    'aprobado', 'rechazado', 'cancelado'
  ));

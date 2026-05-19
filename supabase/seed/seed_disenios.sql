-- Seed diseños de prueba
-- Usuario CEO: 27493f18-1841-4ced-a90c-1114fe5bb8c7
-- Drop Ñ: aaaaaaaa-0001-0001-0001-000000000001
-- Drop EXOTIC0: aaaaaaaa-0001-0001-0001-000000000002

-- 1. Crear Drop 003 si no existe
INSERT INTO public.drops (id, nombre, estado, concepto)
VALUES (
  'aaaaaaaa-0001-0001-0001-000000000003',
  'Drop 003',
  'planificacion',
  'Tercera colección OnExotic'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Insertar diseños de prueba
INSERT INTO public.disenios (titulo, drop_id, disenadora_id, estado, version, fecha_limite)
VALUES
  (
    'Hoodie Volcán',
    'aaaaaaaa-0001-0001-0001-000000000001',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'revision',
    2,
    (CURRENT_DATE + INTERVAL '1 day')::date
  ),
  (
    'Polo Oversize Andes',
    'aaaaaaaa-0001-0001-0001-000000000002',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'proceso',
    1,
    (CURRENT_DATE + INTERVAL '10 days')::date
  ),
  (
    'Short Técnico Pacha',
    'aaaaaaaa-0001-0001-0001-000000000003',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'brief',
    1,
    (CURRENT_DATE + INTERVAL '21 days')::date
  )
ON CONFLICT DO NOTHING;

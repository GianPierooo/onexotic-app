-- Tareas de prueba para OnExotic
-- asignado_a = Gian Piero (CEO)

INSERT INTO public.tareas (titulo, area, prioridad, asignado_a, completado)
VALUES
  ('Registrar marca OnExotic en INDECOPI',  'legal',      'alta',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
  ('Crear email corporativo onexotic.shop', 'tech',       'alta',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
  ('Publicar landing page onexotic.shop',   'tech',       'alta',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
  ('Armar calendario de contenido mayo',    'marketing',  'media', '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
  ('Diseñar packaging de marca',            'disenio',    'media', '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
  ('Confirmar proveedores Drop 001',        'produccion', 'alta',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false)
ON CONFLICT DO NOTHING;

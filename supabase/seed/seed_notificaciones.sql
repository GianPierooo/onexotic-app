-- Seed notificaciones de prueba para Gian Piero
INSERT INTO public.notificaciones (user_id, titulo, mensaje, tipo, leido)
VALUES
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Hoodie Volcán espera aprobación',
    'Camila subió el diseño v2. Revisa y aprueba o rechaza.',
    'disenio',
    false
  ),
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Stock crítico: Polo Classic S',
    'Solo 3 unidades disponibles. Stock mínimo es 5.',
    'inventario',
    false
  ),
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Tarea completada',
    'Andrea marcó como completada: Gestión RRHH Q2',
    'tarea',
    false
  ),
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Reunión diaria confirmada',
    '3 de 4 miembros confirmaron asistencia para hoy.',
    'asistencia',
    true
  ),
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Bono aprobado',
    'Tu bono Q2-2026 de S/ 200.00 ha sido registrado.',
    'bono',
    true
  ),
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    'Bienvenido a OnExotic App',
    'La app interna del equipo ya está lista. ¡A trabajar!',
    'sistema',
    true
  )
ON CONFLICT DO NOTHING;

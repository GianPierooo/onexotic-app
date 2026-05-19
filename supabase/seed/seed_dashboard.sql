-- Seed: datos de prueba para el dashboard
-- CEO UUID: 27493f18-1841-4ced-a90c-1114fe5bb8c7

-- Drops
INSERT INTO public.drops (id, nombre, concepto, fecha_lanzamiento, estado) VALUES
('aaaaaaaa-0001-0001-0001-000000000001', 'Drop N', 'Coleccion urbana inspirada en la identidad peruana', '2026-07-15', 'planificacion'),
('aaaaaaaa-0001-0001-0001-000000000002', 'EXOTIC0', 'Primera coleccion de OnExotic — gymwear de alto rendimiento', '2026-01-15', 'lanzado')
ON CONFLICT (id) DO NOTHING;

-- Productos (2 con stock bajo)
INSERT INTO public.productos (nombre, tipo, drop_id, talla, color, stock, stock_minimo, estado, sku) VALUES
('Polo EXOTIC0 Classic',  'polo',   'aaaaaaaa-0001-0001-0001-000000000002', 'M',  'Negro', 15, 5, 'activo', 'EX-PL-001'),
('Short EXOTIC0 Training','short',  'aaaaaaaa-0001-0001-0001-000000000002', 'L',  'Gris',  3,  5, 'activo', 'EX-SH-001'),
('Polo EXOTIC0 Premium',  'polo',   'aaaaaaaa-0001-0001-0001-000000000002', 'S',  'Blanco',2,  5, 'activo', 'EX-PL-002'),
('Polera EXOTIC0 Zip',    'polera', 'aaaaaaaa-0001-0001-0001-000000000002', 'XL', 'Negro', 20, 5, 'activo', 'EX-PO-001')
ON CONFLICT (sku) DO NOTHING;

-- Tareas pendientes
INSERT INTO public.tareas (titulo, area, prioridad, asignado_a, completado) VALUES
('Preparar catalogo Drop N',    'marketing',  'alta',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
('Revisar disenos de temporada','disenio',    'media', '27493f18-1841-4ced-a90c-1114fe5bb8c7', false),
('Actualizar inventario EXOTIC0','produccion','baja',  '27493f18-1841-4ced-a90c-1114fe5bb8c7', false);

-- Asistencia de hoy
INSERT INTO public.asistencia (user_id, fecha, presente, hora_entrada, reunion_tipo) VALUES
('27493f18-1841-4ced-a90c-1114fe5bb8c7', CURRENT_DATE, true, now(), 'diaria')
ON CONFLICT (user_id, fecha, reunion_tipo) DO NOTHING;

-- Notificaciones
INSERT INTO public.notificaciones (user_id, titulo, mensaje, tipo, leido) VALUES
('27493f18-1841-4ced-a90c-1114fe5bb8c7', 'Stock critico detectado', '2 productos con stock bajo del minimo requerido', 'inventario', false),
('27493f18-1841-4ced-a90c-1114fe5bb8c7', 'Reunion diaria registrada', 'Tu asistencia fue marcada correctamente', 'asistencia', false),
('27493f18-1841-4ced-a90c-1114fe5bb8c7', '3 tareas pendientes', 'Tienes tareas sin completar esta semana', 'tarea', true);

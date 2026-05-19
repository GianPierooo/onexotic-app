-- Seed productos de prueba para inventario OnExotic
-- drop IDs: EXOTIC0=...002, Drop N=...001, Drop 003=...003

INSERT INTO public.productos
  (nombre, tipo, drop_id, talla, color, stock, stock_minimo, costo, precio_venta, estado, sku)
VALUES
  -- EXOTIC0: Polo Classic (3 tallas - S crítico, M ok, L ok)
  ('Polo Classic', 'polo', 'aaaaaaaa-0001-0001-0001-000000000002', 'S', 'Blanco', 3, 5, 35.00, 85.00, 'activo', 'EX-PL-001'),
  ('Polo Classic', 'polo', 'aaaaaaaa-0001-0001-0001-000000000002', 'M', 'Blanco', 18, 5, 35.00, 85.00, 'activo', 'EX-PL-002'),
  ('Polo Classic', 'polo', 'aaaaaaaa-0001-0001-0001-000000000002', 'L', 'Blanco', 9, 5, 35.00, 85.00, 'activo', 'EX-PL-003'),

  -- EXOTIC0: Hoodie Oversize (2 tallas - M crítico)
  ('Hoodie Oversize', 'polera', 'aaaaaaaa-0001-0001-0001-000000000002', 'M', 'Negro', 2, 3, 65.00, 160.00, 'activo', 'EX-HD-001'),
  ('Hoodie Oversize', 'polera', 'aaaaaaaa-0001-0001-0001-000000000002', 'L', 'Negro', 14, 3, 65.00, 160.00, 'activo', 'EX-HD-002'),
  ('Hoodie Oversize', 'polera', 'aaaaaaaa-0001-0001-0001-000000000002', 'XL', 'Negro', 6, 3, 65.00, 160.00, 'activo', 'EX-HD-003'),

  -- Drop N: Short Básico (3 tallas - S agotado, L crítico)
  ('Short Básico', 'short', 'aaaaaaaa-0001-0001-0001-000000000001', 'S', 'Gris', 0, 3, 28.00, 70.00, 'agotado', 'N-SH-001'),
  ('Short Básico', 'short', 'aaaaaaaa-0001-0001-0001-000000000001', 'M', 'Gris', 11, 3, 28.00, 70.00, 'activo', 'N-SH-002'),
  ('Short Básico', 'short', 'aaaaaaaa-0001-0001-0001-000000000001', 'L', 'Gris', 2, 3, 28.00, 70.00, 'activo', 'N-SH-003'),

  -- Drop 003: Polera Andina (3 tallas - XL agotado)
  ('Polera Andina', 'polera', 'aaaaaaaa-0001-0001-0001-000000000003', 'M', 'Terracota', 22, 5, 45.00, 110.00, 'activo', 'D3-PL-001'),
  ('Polera Andina', 'polera', 'aaaaaaaa-0001-0001-0001-000000000003', 'L', 'Terracota', 17, 5, 45.00, 110.00, 'activo', 'D3-PL-002'),
  ('Polera Andina', 'polera', 'aaaaaaaa-0001-0001-0001-000000000003', 'XL', 'Terracota', 0, 5, 45.00, 110.00, 'agotado', 'D3-PL-003'),

  -- Drop 003: Pantalón Cargo (2 tallas)
  ('Pantalón Cargo', 'pantalon', 'aaaaaaaa-0001-0001-0001-000000000003', 'M', 'Olivo', 8, 5, 80.00, 200.00, 'activo', 'D3-PT-001'),
  ('Pantalón Cargo', 'pantalon', 'aaaaaaaa-0001-0001-0001-000000000003', 'L', 'Olivo', 5, 5, 80.00, 200.00, 'activo', 'D3-PT-002')

ON CONFLICT (sku) DO NOTHING;

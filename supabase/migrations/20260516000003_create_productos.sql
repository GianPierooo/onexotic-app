-- Tabla: productos
-- Inventario de prendas OnExotic

CREATE TABLE public.productos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre        text NOT NULL,
  tipo          text NOT NULL CHECK (tipo IN ('polo', 'short', 'pantalon', 'polera', 'accesorio')),
  drop_id       uuid REFERENCES public.drops(id) ON DELETE SET NULL,
  talla         text NOT NULL CHECK (talla IN ('XS', 'S', 'M', 'L', 'XL', 'XXL')),
  color         text,
  stock         integer NOT NULL DEFAULT 0,
  stock_minimo  integer NOT NULL DEFAULT 5,
  costo         decimal(10, 2),
  precio_venta  decimal(10, 2),
  estado        text NOT NULL DEFAULT 'activo'
                CHECK (estado IN ('activo', 'agotado', 'descontinuado')),
  imagen_url    text,
  sku           text UNIQUE,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_productos_drop ON public.productos (drop_id);
CREATE INDEX idx_productos_estado ON public.productos (estado);
CREATE INDEX idx_productos_stock ON public.productos (stock);
CREATE INDEX idx_productos_sku ON public.productos (sku);

-- RLS
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;

-- CEO, Manager y Produccion pueden ver todo (incluido costos)
CREATE POLICY "ceo_manager_produccion_ver_productos" ON public.productos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'produccion')
    )
  );

-- CEO, Manager y Produccion pueden crear/actualizar productos
CREATE POLICY "ceo_manager_produccion_crud_productos" ON public.productos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'produccion')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'produccion')
    )
  );

-- Asociación opcional producto → proveedor.
-- Nullable porque productos legacy y muestras pueden no tener proveedor asignado.
ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS proveedor_id uuid REFERENCES public.proveedores(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_productos_proveedor ON public.productos (proveedor_id);

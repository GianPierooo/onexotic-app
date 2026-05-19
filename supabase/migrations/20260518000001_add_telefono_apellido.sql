-- Agrega campos telefono y apellido a public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS telefono text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS apellido text;

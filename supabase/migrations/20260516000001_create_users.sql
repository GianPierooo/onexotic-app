-- Tabla: users
-- Extiende auth.users de Supabase con datos del perfil OnExotic

CREATE TABLE public.users (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre      text NOT NULL,
  email       text NOT NULL,
  rol         text NOT NULL CHECK (rol IN ('ceo', 'manager', 'disenadora', 'rrhh', 'produccion')),
  avatar_url  text,
  horario     text,
  tema        text NOT NULL DEFAULT 'dark' CHECK (tema IN ('dark', 'light')),
  activo      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indices
CREATE INDEX idx_users_rol ON public.users (rol);
CREATE INDEX idx_users_activo ON public.users (activo);

-- RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Politicas: cada usuario ve su propio perfil
CREATE POLICY "usuarios_ver_propio" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- CEO y RRHH ven todos
CREATE POLICY "ceo_rrhh_ver_todos" ON public.users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'manager', 'rrhh')
    )
  );

-- Cada usuario actualiza su propio perfil (tema, avatar)
CREATE POLICY "usuario_actualizar_propio" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- CEO y RRHH pueden actualizar cualquier perfil
CREATE POLICY "ceo_rrhh_actualizar_todos" ON public.users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol IN ('ceo', 'rrhh')
    )
  );

-- Solo CEO puede insertar nuevos usuarios (crear miembro del equipo)
CREATE POLICY "ceo_insertar_usuarios" ON public.users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND u.rol = 'ceo'
    )
  );

-- Funcion trigger: al crear usuario en auth, insertar en public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, nombre, email, rol)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nombre', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'ceo')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

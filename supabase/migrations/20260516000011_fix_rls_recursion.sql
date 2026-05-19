-- Fix: infinite recursion en políticas RLS de public.users
-- Causa: las políticas consultaban public.users desde dentro de public.users
-- Solución: función SECURITY DEFINER que lee el rol sin activar RLS

-- ─── 1. Función que lee el rol sin recursión ───────────────────────────────
-- SECURITY DEFINER = corre como owner (postgres), sin RLS → no recursión
CREATE OR REPLACE FUNCTION public.get_auth_role()
RETURNS text
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT rol FROM public.users WHERE id = auth.uid();
$$;

-- ─── 2. Eliminar TODAS las políticas actuales de public.users ──────────────
-- (nombres de la migración 000001)
DROP POLICY IF EXISTS "usuarios_ver_propio"        ON public.users;
DROP POLICY IF EXISTS "ceo_rrhh_ver_todos"         ON public.users;
DROP POLICY IF EXISTS "usuario_actualizar_propio"  ON public.users;
DROP POLICY IF EXISTS "ceo_rrhh_actualizar_todos"  ON public.users;
DROP POLICY IF EXISTS "ceo_insertar_usuarios"      ON public.users;
-- por si ya existían del intento anterior
DROP POLICY IF EXISTS "users_select_own"           ON public.users;
DROP POLICY IF EXISTS "users_select_ceo"           ON public.users;
DROP POLICY IF EXISTS "users_select_admin"         ON public.users;
DROP POLICY IF EXISTS "users_update_own"           ON public.users;
DROP POLICY IF EXISTS "users_update_admin"         ON public.users;
DROP POLICY IF EXISTS "users_insert_admin"         ON public.users;

-- ─── 3. Nuevas políticas SIN recursión ────────────────────────────────────

-- Cada usuario ve su propia fila (sin subquery = sin recursión)
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- CEO, Manager y RRHH ven todas las filas
-- get_auth_role() es SECURITY DEFINER → no activa RLS → no recursión
CREATE POLICY "users_select_admin" ON public.users
  FOR SELECT USING (
    public.get_auth_role() IN ('ceo', 'manager', 'rrhh')
  );

-- Cada usuario actualiza su propio perfil
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- CEO y RRHH actualizan cualquier perfil
CREATE POLICY "users_update_admin" ON public.users
  FOR UPDATE USING (
    public.get_auth_role() IN ('ceo', 'rrhh')
  );

-- INSERT: el trigger handle_new_user es SECURITY DEFINER (no usa RLS),
-- esta política aplica cuando se inserta manualmente vía API
CREATE POLICY "users_insert_admin" ON public.users
  FOR INSERT WITH CHECK (
    auth.uid() = id              -- el propio usuario inserta su fila
    OR public.get_auth_role() = 'ceo'   -- o un CEO la inserta
  );

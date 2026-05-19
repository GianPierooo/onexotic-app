-- Establecer contraseñas para usuarios del equipo
-- Requiere pgcrypto (disponible en Supabase por defecto)

UPDATE auth.users
SET
  encrypted_password = crypt('OnExotic2025!', gen_salt('bf')),
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  updated_at = now()
WHERE email IN (
  'luisfelipe@onexotic.shop',
  'camila@onexotic.shop',
  'andrea@onexotic.shop'
);

-- Confirmar email de Gian Piero también
UPDATE auth.users
SET email_confirmed_at = COALESCE(email_confirmed_at, now())
WHERE email = 'gianpierodaniel@gmail.com';

-- Seed bonos Q2-2026
INSERT INTO public.bonos (user_id, monto, motivo, periodo, aprobado_por)
VALUES
  (
    '27493f18-1841-4ced-a90c-1114fe5bb8c7',
    200.00,
    'Cierre exitoso EXOTIC0',
    'Q2-2026',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7'
  ),
  (
    '609e25a1-7851-481b-9d7d-15b4f915916d',
    350.00,
    'Diseños aprobados Drop Ñ',
    'Q2-2026',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7'
  ),
  (
    '033a9bc1-1091-42a0-9a49-03fbd784bdc3',
    150.00,
    'Gestión RRHH Q2',
    'Q2-2026',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7'
  ),
  (
    '61df06a5-a7e1-400a-bf50-baa359baee77',
    200.00,
    'Coordinación producción Drop Ñ',
    'Q2-2026',
    '27493f18-1841-4ced-a90c-1114fe5bb8c7'
  )
ON CONFLICT DO NOTHING;

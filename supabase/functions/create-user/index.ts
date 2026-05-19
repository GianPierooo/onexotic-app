import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Verificar JWT del llamador
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Sin autorización" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "No autorizado" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Verificar que el llamador tiene rol 'ceo'
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: callerData } = await supabaseAdmin
      .from("users")
      .select("rol")
      .eq("id", user.id)
      .single();

    if (callerData?.rol !== "ceo") {
      return new Response(
        JSON.stringify({ error: "Solo los CEOs pueden registrar miembros del equipo" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Parse body
    const { email, password, nombre, apellido, rol, horario, telefono, notas } =
      await req.json();

    // Validar campos obligatorios
    if (!email || !password || !nombre || !rol) {
      return new Response(
        JSON.stringify({ error: "Faltan campos obligatorios: email, password, nombre, rol" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validar rol
    const rolesValidos = ["ceo", "manager", "disenadora", "rrhh", "produccion"];
    if (!rolesValidos.includes(rol)) {
      return new Response(
        JSON.stringify({ error: `Rol inválido. Opciones: ${rolesValidos.join(", ")}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Verificar que el email no existe ya
    const { data: existing } = await supabaseAdmin
      .from("users")
      .select("id")
      .eq("email", email)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({ error: "Ya existe un usuario con ese correo electrónico" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Crear usuario en auth
    const { data: newUser, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { nombre, rol },
      });

    if (createError || !newUser.user) {
      console.error("Error creando auth user:", createError);
      return new Response(
        JSON.stringify({
          error: createError?.message ?? "Error al crear el usuario. Intenta de nuevo.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Actualizar el perfil en public.users con todos los datos
    // (el trigger handle_new_user crea una fila básica; la completamos)
    const { error: updateError } = await supabaseAdmin
      .from("users")
      .update({
        nombre,
        apellido: apellido ?? null,
        rol,
        horario: horario ?? null,
        telefono: telefono ?? null,
        activo: true,
        tema: "dark",
      })
      .eq("id", newUser.user.id);

    if (updateError) {
      console.error("Error actualizando perfil:", updateError);
      // No falla — el usuario de auth fue creado exitosamente
    }

    return new Response(
      JSON.stringify({
        id: newUser.user.id,
        mensaje: "Usuario creado exitosamente",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error en create-user:", error);
    return new Response(
      JSON.stringify({ error: "Error interno del servidor" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

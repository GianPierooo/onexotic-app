import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const AI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
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
    // 1. Verificar JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Obtener rol y nombre del usuario
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: userData } = await supabaseAdmin
      .from("users")
      .select("nombre, rol")
      .eq("id", user.id)
      .single();

    const rol = userData?.rol ?? "ceo";
    const nombre = userData?.nombre ?? "Equipo";

    // 3. Parse body
    const { mensaje, historial = [] } = await req.json();

    if (!mensaje || typeof mensaje !== "string") {
      return new Response(
        JSON.stringify({ respuesta: "No tengo esa información disponible." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Construir context_data según rol
    const contextData = await buildContext(supabaseAdmin, rol, user.id);

    // 5. Construir system prompt
    const systemPrompt = buildSystemPrompt(rol, nombre, contextData);

    // 6. Armar mensajes (últimos 6 del historial + el nuevo)
    const messages = [
      ...historial.slice(-6),
      { role: "user", content: mensaje },
    ];

    // 7. Llamar IA OnExotic
    const iaRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${AI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        max_tokens: 80,
        messages: [
          { role: "system", content: systemPrompt },
          ...messages,
        ],
      }),
    });

    const aiData = await iaRes.json();

    if (!iaRes.ok) {
      console.error("IA OnExotic error:", aiData);
      throw new Error(aiData.error?.message ?? "Error en IA OnExotic");
    }

    const respuesta =
      aiData.choices?.[0]?.message?.content ?? "No tengo esa información disponible.";

    return new Response(JSON.stringify({ respuesta }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error en ai-chat:", error);
    return new Response(
      JSON.stringify({ respuesta: "No tengo esa información disponible." }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ─── Builder de contexto por rol ──────────────────────────────────────────────

async function buildContext(
  supabase: ReturnType<typeof createClient>,
  rol: string,
  userId: string
): Promise<string> {
  const today = new Date().toISOString().split("T")[0];

  try {
    if (rol === "ceo" || rol === "manager") {
      const [productos, tareas, asistencia, drops] = await Promise.all([
        supabase
          .from("productos")
          .select("nombre, stock, stock_minimo, estado")
          .eq("estado", "activo")
          .limit(30),
        supabase
          .from("tareas")
          .select("titulo, area, prioridad, fecha_limite")
          .eq("completado", false)
          .limit(20),
        supabase
          .from("asistencia")
          .select("user_id, presente")
          .eq("fecha", today)
          .eq("reunion_tipo", "diaria"),
        supabase
          .from("drops")
          .select("nombre, estado, fecha_lanzamiento")
          .limit(5),
      ]);

      const stockCritico = (productos.data ?? []).filter(
        (p: Record<string, unknown>) =>
          (p.stock as number) <= (p.stock_minimo as number)
      );
      const presentes = (asistencia.data ?? []).filter(
        (a: Record<string, unknown>) => a.presente
      ).length;

      return JSON.stringify({
        fecha: today,
        stockCritico: stockCritico.map(
          (p: Record<string, unknown>) => `${p.nombre}: ${p.stock} uds`
        ),
        tareasPendientes: (tareas.data ?? [])
          .slice(0, 10)
          .map(
            (t: Record<string, unknown>) =>
              `${t.titulo} (${t.area}, ${t.prioridad})`
          ),
        asistenciaHoy: `${presentes}/${(asistencia.data ?? []).length} presentes`,
        drops: (drops.data ?? []).map(
          (d: Record<string, unknown>) => `${d.nombre}: ${d.estado}`
        ),
      });
    }

    if (rol === "disenadora") {
      const [disenios, briefs, tareas] = await Promise.all([
        supabase
          .from("disenios")
          .select("titulo, estado, fecha_limite")
          .eq("disenadora_id", userId)
          .limit(10),
        supabase
          .from("briefs")
          .select("titulo, descripcion, fecha_limite")
          .limit(5),
        supabase
          .from("tareas")
          .select("titulo, prioridad, fecha_limite")
          .eq("asignado_a", userId)
          .eq("completado", false)
          .limit(10),
      ]);

      return JSON.stringify({
        fecha: today,
        misDisenios: (disenios.data ?? []).map(
          (d: Record<string, unknown>) => `${d.titulo}: ${d.estado}`
        ),
        briefs: (briefs.data ?? []).map(
          (b: Record<string, unknown>) =>
            `${b.titulo} - límite: ${b.fecha_limite}`
        ),
        misTareas: (tareas.data ?? []).map(
          (t: Record<string, unknown>) => t.titulo
        ),
      });
    }

    if (rol === "rrhh") {
      const [asistencia, bonos, equipo] = await Promise.all([
        supabase
          .from("asistencia")
          .select("user_id, presente, nota")
          .eq("fecha", today),
        supabase
          .from("bonos")
          .select("user_id, monto, motivo, periodo")
          .limit(10),
        supabase
          .from("users")
          .select("nombre, rol, activo")
          .eq("activo", true),
      ]);

      const presentes = (asistencia.data ?? []).filter(
        (a: Record<string, unknown>) => a.presente
      ).length;

      return JSON.stringify({
        fecha: today,
        asistenciaHoy: `${presentes}/${(asistencia.data ?? []).length} presentes`,
        bonosPendientes: (bonos.data ?? []).length,
        equipo: (equipo.data ?? []).map(
          (u: Record<string, unknown>) => `${u.nombre} (${u.rol})`
        ),
      });
    }

    if (rol === "produccion") {
      const [productos, drops, proveedores, tareas] = await Promise.all([
        supabase
          .from("productos")
          .select("nombre, stock, stock_minimo, talla")
          .eq("estado", "activo")
          .limit(20),
        supabase
          .from("drops")
          .select("nombre, estado, fecha_lanzamiento")
          .limit(5),
        supabase
          .from("proveedores")
          .select("nombre, tipo, rating")
          .eq("activo", true)
          .limit(10),
        supabase
          .from("tareas")
          .select("titulo, prioridad")
          .eq("asignado_a", userId)
          .eq("completado", false)
          .limit(10),
      ]);

      return JSON.stringify({
        fecha: today,
        stockActual: (productos.data ?? []).map(
          (p: Record<string, unknown>) =>
            `${p.nombre} T:${p.talla}: ${p.stock} uds`
        ),
        drops: (drops.data ?? []).map(
          (d: Record<string, unknown>) => `${d.nombre}: ${d.estado}`
        ),
        proveedores: (proveedores.data ?? []).map(
          (p: Record<string, unknown>) => `${p.nombre} (${p.tipo})`
        ),
        misTareas: (tareas.data ?? []).map(
          (t: Record<string, unknown>) => t.titulo
        ),
      });
    }

    return JSON.stringify({ fecha: today });
  } catch (e) {
    console.error("buildContext error:", e);
    return JSON.stringify({ fecha: today });
  }
}

// ─── System prompts por rol ────────────────────────────────────────────────────

const ONEXOTIC_BASE = `OnExotic es una marca peruana de ropa (gymwear, urbano, streetwear) fundada en 2025. Opera por drops limitados: EXOTIC0 (lanzado), Ñ (en producción), Drop 003 (planificación). Vende por Instagram, TikTok, Facebook y WhatsApp. Web: onexotic.shop. Equipo: Gian Piero (CEO Tech), Luis Felipe (CEO Producción), Roma (Diseñadora), Andrea (RRHH).`;

function buildSystemPrompt(rol: string, nombre: string, contextData: string): string {
  switch (rol) {
    case "ceo":
    case "manager":
      return `Eres el asistente interno de OnExotic. ${ONEXOTIC_BASE} Responde preguntas sobre la marca, el equipo, drops, inventario, diseños y tareas. Máximo 2 líneas. Solo texto plano. Sin formato. Sin mencionar IA, Claude ni OpenAI. El usuario es ${nombre}. Si no tienes el dato exacto, responde con lo que sabes de la marca de forma útil. Contexto actual: ${contextData}`;

    case "disenadora":
      return `Eres el asistente de OnExotic para el área de diseño. ${ONEXOTIC_BASE} Puedes responder sobre: tus diseños y briefs asignados, tendencias de moda, paletas de color, tipografía, conceptos de diseño, reuniones del equipo y tu calendario. Para saludos responde de forma amigable y breve. Máximo 2 líneas. Solo texto plano. Sin formato. Sin mencionar IA, Claude ni OpenAI. El usuario es ${nombre}. Contexto: ${contextData}`;

    case "rrhh":
      return `Eres el asistente RRHH de OnExotic. ${ONEXOTIC_BASE} Solo asistencia y equipo. Máximo 2 líneas. Solo texto plano. Si preguntan fuera de tu scope: "No tengo acceso a esa información." El usuario es ${nombre}. Contexto: ${contextData}`;

    case "produccion":
      return `Eres el asistente de producción de OnExotic. ${ONEXOTIC_BASE} Solo stock y proveedores. Máximo 2 líneas. Solo texto plano. Si preguntan fuera de tu scope: "No tengo acceso a esa información." El usuario es ${nombre}. Contexto: ${contextData}`;

    default:
      return `Eres el asistente interno de OnExotic. ${ONEXOTIC_BASE} Máximo 2 líneas. Solo texto plano. Sin formato. El usuario es ${nombre}. Contexto: ${contextData}`;
  }
}

// Edge function ai-asistente — Modo Asistente IA (solo CEO/manager).
//
// Diferente a ai-chat:
//  · Soporta tool calling (function calling) con OpenAI.
//  · Devuelve { tipo: 'texto' } o { tipo: 'tool_call', tool, args,
//    requiere_confirmacion, resumen }.
//  · El cliente Flutter ejecuta la acción contra los providers existentes
//    (reusa notificaciones FCM, invalidaciones de cache, etc.).
//  · Validación estricta de rol: 403 si no es ceo/manager.
//
// El system prompt incluye:
//  · Lista de usuarios activos (id, nombre, rol) para resolver "Roma" → uuid.
//  · Lista de drops (id, nombre) para asociar briefs.
//  · Fecha actual (Lima) para resolver "viernes" → YYYY-MM-DD.

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

// ─── Tool definitions (OpenAI function calling) ───────────────────────────────

const tools = [
  {
    type: "function",
    function: {
      name: "crear_tarea",
      description:
        "Crea una nueva tarea en el sistema. Se ejecuta DIRECTO sin confirmación.",
      parameters: {
        type: "object",
        properties: {
          titulo: { type: "string", description: "Título breve de la tarea" },
          descripcion: { type: "string" },
          area: {
            type: "string",
            enum: ["tech", "disenio", "marketing", "produccion", "rrhh", "legal"],
          },
          prioridad: { type: "string", enum: ["alta", "media", "baja"] },
          asignado_a_id: {
            type: "string",
            description:
              "UUID exacto del usuario a quien se asigna (de la lista de usuarios del contexto). Omitir si nadie específico.",
          },
          fecha_limite: {
            type: "string",
            description: "Fecha YYYY-MM-DD. Omitir si no se especificó.",
          },
        },
        required: ["titulo", "area", "prioridad"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "crear_evento",
      description:
        "Crea un evento en el calendario. Se ejecuta DIRECTO sin confirmación.",
      parameters: {
        type: "object",
        properties: {
          tipo: {
            type: "string",
            description:
              "Tipo libre: 'Reunión de equipo', 'Cumpleaños', 'Sesión de fotos', etc.",
          },
          titulo: { type: "string" },
          fecha: { type: "string", description: "YYYY-MM-DD" },
          hora: {
            type: "string",
            description: "HH:MM en formato 24h. Omitir si no hay hora fija.",
          },
          lugar: { type: "string" },
          descripcion: { type: "string" },
        },
        required: ["tipo", "titulo", "fecha"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "crear_brief",
      description:
        "Crea un brief de diseño con su entrada de diseño asociada. Requiere CONFIRMACIÓN del CEO antes de ejecutar.",
      parameters: {
        type: "object",
        properties: {
          titulo: { type: "string" },
          drop_id: {
            type: "string",
            description: "UUID del drop (de la lista del contexto)",
          },
          descripcion: { type: "string" },
          colores: {
            type: "array",
            items: { type: "string" },
            description: "Códigos hex de colores, ej. ['#FF4500', '#000000']",
          },
          fecha_limite: { type: "string", description: "YYYY-MM-DD" },
          notas: { type: "string" },
        },
        required: ["titulo", "drop_id", "descripcion", "fecha_limite"],
      },
    },
  },
];

// crear_brief es el único que pide confirmación previa.
const TOOLS_QUE_REQUIEREN_CONFIRMACION = new Set(["crear_brief"]);

// ─── Builder del resumen humano para confirmaciones ───────────────────────────

function resumenAccion(
  tool: string,
  args: Record<string, unknown>,
  catalogo: Record<string, Map<string, string>>
): string {
  if (tool === "crear_tarea") {
    const partes: string[] = [`Tarea: ${args.titulo}`];
    if (args.area) partes.push(`Área: ${args.area}`);
    if (args.prioridad) partes.push(`Prioridad: ${args.prioridad}`);
    if (args.asignado_a_id) {
      const nombre = catalogo.users.get(args.asignado_a_id as string);
      partes.push(`Asignada a: ${nombre ?? "—"}`);
    }
    if (args.fecha_limite) partes.push(`Fecha límite: ${args.fecha_limite}`);
    return partes.join(" · ");
  }
  if (tool === "crear_evento") {
    const partes: string[] = [`${args.tipo}: ${args.titulo}`];
    partes.push(`${args.fecha}${args.hora ? ` a las ${args.hora}` : ""}`);
    if (args.lugar) partes.push(`Lugar: ${args.lugar}`);
    return partes.join(" · ");
  }
  if (tool === "crear_brief") {
    const partes: string[] = [`Brief: ${args.titulo}`];
    if (args.drop_id) {
      const nombre = catalogo.drops.get(args.drop_id as string);
      partes.push(`Drop: ${nombre ?? "—"}`);
    }
    if (args.fecha_limite) partes.push(`Entrega: ${args.fecha_limite}`);
    if (Array.isArray(args.colores) && args.colores.length > 0) {
      partes.push(`Colores: ${(args.colores as string[]).join(", ")}`);
    }
    return partes.join(" · ");
  }
  return tool;
}

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Verificar JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "No authorization" }, 401);

    const supabaseUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser();
    if (authError || !user) return json({ error: "Unauthorized" }, 401);

    // 2. Validar rol CEO/manager
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: userData } = await supabaseAdmin
      .from("users")
      .select("nombre, rol")
      .eq("id", user.id)
      .single();
    const rol = userData?.rol;
    const nombre = userData?.nombre ?? "Equipo";
    if (rol !== "ceo" && rol !== "manager") {
      return json(
        { error: "Modo Asistente disponible solo para CEO/Manager" },
        403
      );
    }

    // 3. Parse body
    const { mensaje, historial = [] } = await req.json();
    if (!mensaje || typeof mensaje !== "string") {
      return json({
        tipo: "texto",
        respuesta: "No entendí la solicitud.",
      });
    }

    // 4. Cargar contexto: usuarios activos + drops + fecha
    const [usuariosRes, dropsRes] = await Promise.all([
      supabaseAdmin
        .from("users")
        .select("id, nombre, rol")
        .eq("activo", true)
        .order("nombre"),
      supabaseAdmin
        .from("drops")
        .select("id, nombre, estado")
        .order("created_at", { ascending: false }),
    ]);

    const usuariosMap = new Map<string, string>();
    (usuariosRes.data ?? []).forEach((u: Record<string, unknown>) =>
      usuariosMap.set(u.id as string, u.nombre as string)
    );
    const dropsMap = new Map<string, string>();
    (dropsRes.data ?? []).forEach((d: Record<string, unknown>) =>
      dropsMap.set(d.id as string, d.nombre as string)
    );

    const catalogo = { users: usuariosMap, drops: dropsMap };

    // Fecha actual en Lima (UTC-5)
    const ahora = new Date();
    const limaTs = ahora.getTime() - 5 * 60 * 60 * 1000;
    const hoy = new Date(limaTs).toISOString().split("T")[0];
    const diasSemana = [
      "domingo",
      "lunes",
      "martes",
      "miércoles",
      "jueves",
      "viernes",
      "sábado",
    ];
    const diaNombre = diasSemana[new Date(limaTs).getUTCDay()];

    // 5. System prompt
    const systemPrompt = buildSystemPrompt({
      nombre,
      hoy,
      diaNombre,
      usuarios: usuariosRes.data ?? [],
      drops: dropsRes.data ?? [],
    });

    // 6. Llamar OpenAI con tool calling
    const messages = [
      { role: "system", content: systemPrompt },
      ...historial.slice(-6),
      { role: "user", content: mensaje },
    ];

    const iaRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${AI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        max_tokens: 400,
        temperature: 0.3,
        messages,
        tools,
        tool_choice: "auto",
      }),
    });

    const aiData = await iaRes.json();
    if (!iaRes.ok) {
      console.error("ai-asistente IA error:", aiData);
      throw new Error(aiData.error?.message ?? "Error en IA");
    }

    const message = aiData.choices?.[0]?.message;
    const toolCall = message?.tool_calls?.[0];

    if (toolCall && toolCall.function) {
      const toolName = toolCall.function.name as string;
      let args: Record<string, unknown> = {};
      try {
        args = JSON.parse(toolCall.function.arguments ?? "{}");
      } catch (_) {
        args = {};
      }
      const requiere = TOOLS_QUE_REQUIEREN_CONFIRMACION.has(toolName);
      return json({
        tipo: "tool_call",
        tool: toolName,
        args,
        requiere_confirmacion: requiere,
        resumen: resumenAccion(toolName, args, catalogo),
      });
    }

    // Texto plano (preguntas de aclaración, conversación general)
    const respuesta =
      message?.content?.trim() ?? "No tengo esa información disponible.";
    return json({ tipo: "texto", respuesta });
  } catch (error) {
    console.error("Error en ai-asistente:", error);
    return json({
      tipo: "texto",
      respuesta: "Hubo un error procesando tu solicitud.",
    });
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ─── System prompt ────────────────────────────────────────────────────────────

function buildSystemPrompt(ctx: {
  nombre: string;
  hoy: string;
  diaNombre: string;
  usuarios: Record<string, unknown>[];
  drops: Record<string, unknown>[];
}): string {
  const usuariosTxt = ctx.usuarios
    .map((u) => `  - ${u.nombre} (${u.rol}) → id: ${u.id}`)
    .join("\n");
  const dropsTxt = ctx.drops
    .map((d) => `  - ${d.nombre} (${d.estado}) → id: ${d.id}`)
    .join("\n");

  return `Eres el Asistente de OnExotic en MODO ACCIONES. El usuario actual es ${ctx.nombre} (CEO).

Hoy es ${ctx.diaNombre} ${ctx.hoy} (zona horaria Lima, Perú).

OnExotic es una marca peruana de ropa (gymwear, urbano, streetwear). Equipo de 4 personas. Comunicación en español.

TU TRABAJO:
- Interpretar lo que pide el CEO en lenguaje natural y ejecutar acciones reales en el sistema vía tool calling.
- Resuelves nombres y fechas: cuando dice "Roma" buscas el UUID en la lista de usuarios; cuando dice "el viernes" calculas la próxima fecha YYYY-MM-DD; cuando dice "el drop Ñ" usas el id correspondiente.
- Si te falta un dato OBLIGATORIO de la herramienta, NO inventes — pregunta brevemente al CEO.
- Si te faltan datos opcionales (descripción, lugar, notas), no preguntes — omítelos.
- Para crear_tarea, infiere el área del contexto: diseño de banner → "disenio"; arreglar bug → "tech"; campaña → "marketing"; producir prenda → "produccion"; contratar/asistencia → "rrhh"; INDECOPI/contratos → "legal".
- Si la prioridad no se menciona, asume "media".
- Para crear_brief el campo descripcion es obligatorio: si el CEO no lo dio, pregúntalo.
- Si el CEO solo conversa o pregunta algo informativo (no una orden de crear), responde en texto plano breve sin invocar herramientas.

USUARIOS ACTIVOS (usa el id exacto para asignar tareas):
${usuariosTxt || "  (sin usuarios)"}

DROPS DISPONIBLES (usa el id exacto en crear_brief):
${dropsTxt || "  (sin drops)"}

REGLAS DE ESTILO:
- Mensajes muy breves (1-2 líneas).
- Solo texto plano, sin markdown, sin bullets.
- Nunca expongas IDs ni UUIDs en tus respuestas al usuario.`;
}

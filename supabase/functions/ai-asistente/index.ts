// Edge function ai-asistente — Modo Asistente IA (solo CEO/manager).
//
// Cambios vs versión anterior:
//  · System prompt MUCHO más estricto: la IA debe preguntar parámetros
//    faltantes uno a la vez antes de invocar herramientas, NO inferir.
//  · TODAS las tools (crear_tarea, crear_evento, crear_brief) requieren
//    confirmación previa via burbuja en el cliente (doble check después
//    del resumen textual que la IA da).
//  · Soporte de visión: el body puede incluir `imagenes_urls` (array de
//    URLs públicas de Supabase Storage). Se convierten en contenido
//    multimodal (image_url) para gpt-4o-mini, que soporta visión.

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
        "Crea una tarea. SOLO invocar cuando se hayan recopilado y confirmado todos los datos con el usuario.",
      parameters: {
        type: "object",
        properties: {
          titulo: { type: "string" },
          descripcion: { type: "string" },
          area: {
            type: "string",
            enum: ["tech", "disenio", "marketing", "produccion", "rrhh", "legal"],
          },
          prioridad: { type: "string", enum: ["alta", "media", "baja"] },
          asignado_a_id: {
            type: "string",
            description:
              "UUID exacto del usuario asignado (de la lista del contexto). Omitir si el CEO explícitamente dijo 'sin asignar'.",
          },
          fecha_limite: {
            type: "string",
            description:
              "YYYY-MM-DD. Omitir si el CEO explícitamente dijo 'sin fecha'.",
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
        "Crea un evento de calendario. SOLO invocar cuando se hayan recopilado y confirmado todos los datos con el usuario.",
      parameters: {
        type: "object",
        properties: {
          tipo: {
            type: "string",
            enum: [
              "reunion",
              "lanzamiento_drop",
              "fecha_limite_disenio",
              "fecha_limite_tarea",
              "evento_especial",
            ],
          },
          titulo: { type: "string" },
          fecha: { type: "string", description: "YYYY-MM-DD" },
          hora: {
            type: "string",
            description:
              "HH:MM en 24h. Omitir si el CEO explícitamente dijo 'sin hora'.",
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
        "Crea un brief de diseño. SOLO invocar cuando se hayan recopilado y confirmado todos los datos con el usuario.",
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
            description:
              "Códigos hex, ej. ['#FF4500']. Omitir si el CEO dijo 'sin colores'.",
          },
          tipografia: { type: "string" },
          fecha_limite: { type: "string", description: "YYYY-MM-DD" },
          notas: { type: "string" },
          usar_imagenes_adjuntas: {
            type: "boolean",
            description:
              "true si las imágenes adjuntas al chat deben quedar como referencias del brief.",
          },
        },
        required: ["titulo", "drop_id", "descripcion", "fecha_limite"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "aprobar_disenio",
      description:
        "Aprueba un diseño que está en estado 'revision' o 'avance'. Notifica a la diseñadora.",
      parameters: {
        type: "object",
        properties: {
          disenio_id: {
            type: "string",
            description:
              "UUID exacto del diseño (de la lista DISEÑOS PENDIENTES del contexto).",
          },
        },
        required: ["disenio_id"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "rechazar_disenio",
      description:
        "Rechaza un diseño con feedback obligatorio. La diseñadora recibe el motivo por notificación.",
      parameters: {
        type: "object",
        properties: {
          disenio_id: { type: "string" },
          feedback: {
            type: "string",
            description: "Motivo del rechazo. Obligatorio.",
          },
        },
        required: ["disenio_id", "feedback"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "crear_drop",
      description: "Crea un drop nuevo en la línea de producción.",
      parameters: {
        type: "object",
        properties: {
          nombre: {
            type: "string",
            description: "Ej. 'Drop 004', 'EXOTIC1', 'Ñ'",
          },
          concepto: { type: "string" },
          estado: {
            type: "string",
            enum: ["planificacion", "produccion", "lanzado", "agotado"],
            description: "Por defecto 'planificacion'.",
          },
          fecha_lanzamiento: { type: "string", description: "YYYY-MM-DD" },
        },
        required: ["nombre"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "crear_bono",
      description:
        "Asigna un bono monetario a un miembro del equipo. Se notifica al receptor.",
      parameters: {
        type: "object",
        properties: {
          user_id: {
            type: "string",
            description: "UUID del usuario (de la lista USUARIOS ACTIVOS).",
          },
          monto: {
            type: "number",
            description: "Monto en soles peruanos (PEN). Ej. 200, 150.50.",
          },
          motivo: { type: "string" },
          periodo: {
            type: "string",
            description:
              "Periodo del bono. Por defecto el trimestre actual, ej. 'Q2-2026'. Omitir si el CEO no lo dijo y se calculará automáticamente.",
          },
        },
        required: ["user_id", "monto", "motivo"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "anuncio_equipo",
      description:
        "Envía una notificación broadcast a todos los miembros activos del equipo. Usar con cuidado, es invasivo.",
      parameters: {
        type: "object",
        properties: {
          titulo: { type: "string" },
          mensaje: { type: "string" },
        },
        required: ["titulo", "mensaje"],
      },
    },
  },
];

// Todas las tools de acción pasan por confirmación en el cliente.
// Las más destructivas (rechazar, anuncio) ESPECIALMENTE — el resumen
// final es la última defensa antes de afectar al equipo.
const TOOLS_QUE_REQUIEREN_CONFIRMACION = new Set([
  "crear_tarea",
  "crear_evento",
  "crear_brief",
  "aprobar_disenio",
  "rechazar_disenio",
  "crear_drop",
  "crear_bono",
  "anuncio_equipo",
]);

// ─── Resumen humano para la burbuja de confirmación ───────────────────────────

function resumenAccion(
  tool: string,
  args: Record<string, unknown>,
  catalogo: Record<string, Map<string, string>>,
  imagenesCount: number
): string {
  if (tool === "crear_tarea") {
    const partes: string[] = [`Tarea: ${args.titulo}`];
    if (args.area) partes.push(`Área: ${args.area}`);
    if (args.prioridad) partes.push(`Prioridad: ${args.prioridad}`);
    if (args.asignado_a_id) {
      const nombre = catalogo.users.get(args.asignado_a_id as string);
      partes.push(`Asignada a: ${nombre ?? "—"}`);
    } else {
      partes.push("Sin asignar");
    }
    if (args.fecha_limite) {
      partes.push(`Fecha límite: ${args.fecha_limite}`);
    } else {
      partes.push("Sin fecha límite");
    }
    if (args.descripcion) partes.push(`Descripción: ${args.descripcion}`);
    return partes.join("\n");
  }
  if (tool === "crear_evento") {
    const partes: string[] = [`Tipo: ${args.tipo}`];
    partes.push(`Título: ${args.titulo}`);
    partes.push(
      `Fecha: ${args.fecha}${args.hora ? ` · Hora: ${args.hora}` : " · Sin hora"}`
    );
    if (args.lugar) partes.push(`Lugar: ${args.lugar}`);
    if (args.descripcion) partes.push(`Descripción: ${args.descripcion}`);
    return partes.join("\n");
  }
  if (tool === "aprobar_disenio") {
    const titulo = catalogo.disenios.get(args.disenio_id as string);
    return `Aprobar diseño: ${titulo ?? "—"}\nLa diseñadora recibirá una notificación.`;
  }
  if (tool === "rechazar_disenio") {
    const titulo = catalogo.disenios.get(args.disenio_id as string);
    return `Rechazar diseño: ${titulo ?? "—"}\nMotivo: ${args.feedback}\nLa diseñadora recibirá el feedback.`;
  }
  if (tool === "crear_drop") {
    const partes: string[] = [`Drop: ${args.nombre}`];
    if (args.concepto) partes.push(`Concepto: ${args.concepto}`);
    partes.push(`Estado: ${args.estado ?? "planificacion"}`);
    if (args.fecha_lanzamiento) {
      partes.push(`Lanzamiento: ${args.fecha_lanzamiento}`);
    }
    return partes.join("\n");
  }
  if (tool === "crear_bono") {
    const nombre = catalogo.users.get(args.user_id as string);
    const partes: string[] = [`Bono para: ${nombre ?? "—"}`];
    partes.push(`Monto: S/ ${args.monto}`);
    partes.push(`Motivo: ${args.motivo}`);
    if (args.periodo) partes.push(`Periodo: ${args.periodo}`);
    return partes.join("\n");
  }
  if (tool === "anuncio_equipo") {
    return `Anuncio al equipo (a TODOS los miembros activos):\n\n«${args.titulo}»\n${args.mensaje}`;
  }
  if (tool === "crear_brief") {
    const partes: string[] = [`Brief: ${args.titulo}`];
    if (args.drop_id) {
      const nombre = catalogo.drops.get(args.drop_id as string);
      partes.push(`Drop: ${nombre ?? "—"}`);
    }
    partes.push(`Entrega: ${args.fecha_limite}`);
    partes.push(`Descripción: ${args.descripcion}`);
    if (Array.isArray(args.colores) && (args.colores as string[]).length > 0) {
      partes.push(`Colores: ${(args.colores as string[]).join(", ")}`);
    }
    if (args.tipografia) partes.push(`Tipografía: ${args.tipografia}`);
    if (args.notas) partes.push(`Notas: ${args.notas}`);
    if (args.usar_imagenes_adjuntas && imagenesCount > 0) {
      partes.push(
        `Referencias: ${imagenesCount} ${
          imagenesCount === 1 ? "imagen" : "imágenes"
        } adjunta${imagenesCount === 1 ? "" : "s"}`
      );
    }
    return partes.join("\n");
  }
  return tool;
}

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Auth + rol
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

    // 2. Parse body
    const {
      mensaje,
      historial = [],
      imagenes_urls = [],
    } = await req.json();

    if (!mensaje || typeof mensaje !== "string") {
      return json({ tipo: "texto", respuesta: "No entendí la solicitud." });
    }

    const imagenes: string[] = Array.isArray(imagenes_urls)
      ? imagenes_urls.filter((u) => typeof u === "string" && u.length > 0)
      : [];

    // 3. Contexto: users + drops + diseños pendientes + fecha
    const [usuariosRes, dropsRes, diseniosRes] = await Promise.all([
      supabaseAdmin
        .from("users")
        .select("id, nombre, rol")
        .eq("activo", true)
        .order("nombre"),
      supabaseAdmin
        .from("drops")
        .select("id, nombre, estado")
        .order("created_at", { ascending: false }),
      supabaseAdmin
        .from("disenios")
        .select("id, titulo, estado, disenadora_id, fecha_limite")
        .in("estado", ["revision", "avance"])
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
    const diseniosMap = new Map<string, string>();
    (diseniosRes.data ?? []).forEach((d: Record<string, unknown>) =>
      diseniosMap.set(d.id as string, d.titulo as string)
    );

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

    // 4. System prompt
    const systemPrompt = buildSystemPrompt({
      nombre,
      hoy,
      diaNombre,
      usuarios: usuariosRes.data ?? [],
      drops: dropsRes.data ?? [],
      disenios: diseniosRes.data ?? [],
      hayImagenes: imagenes.length > 0,
    });

    // 5. Mensajes para OpenAI — el último mensaje del user puede ser multimodal
    const userContent: unknown =
      imagenes.length > 0
        ? [
            { type: "text", text: mensaje },
            ...imagenes.map((url) => ({
              type: "image_url",
              image_url: { url },
            })),
          ]
        : mensaje;

    const messages = [
      { role: "system", content: systemPrompt },
      ...historial.slice(-6),
      { role: "user", content: userContent },
    ];

    // 6. Llamar OpenAI
    const iaRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${AI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        max_tokens: 500,
        temperature: 0.2,
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
        resumen: resumenAccion(
          toolName,
          args,
          {
            users: usuariosMap,
            drops: dropsMap,
            disenios: diseniosMap,
          },
          imagenes.length
        ),
        // Devolver las URLs al cliente para que las inserte en el brief.
        imagenes_urls: imagenes,
      });
    }

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
  disenios: Record<string, unknown>[];
  hayImagenes: boolean;
}): string {
  const usuariosTxt = ctx.usuarios
    .map((u) => `  - ${u.nombre} (${u.rol}) → id: ${u.id}`)
    .join("\n");
  const dropsTxt = ctx.drops
    .map((d) => `  - ${d.nombre} (${d.estado}) → id: ${d.id}`)
    .join("\n");
  const diseniosTxt = ctx.disenios.length === 0
    ? "  (sin diseños pendientes de revisión)"
    : ctx.disenios
        .map((d) => {
          const disenadora = ctx.usuarios.find((u) => u.id === d.disenadora_id);
          const nombreD = disenadora?.nombre ?? "—";
          return `  - "${d.titulo}" (estado: ${d.estado}, diseñadora: ${nombreD}, entrega: ${d.fecha_limite ?? "?"}) → id: ${d.id}`;
        })
        .join("\n");

  const visionLine = ctx.hayImagenes
    ? "El CEO adjuntó imágenes en este turno: puedes analizarlas para proponer colores, descripción y conceptos cuando sea relevante (especialmente para briefs). Si decides crear un brief, marca usar_imagenes_adjuntas=true para que queden como referencias del brief."
    : "";

  return `Eres el Asistente de OnExotic en MODO ACCIONES. El usuario actual es ${ctx.nombre} (CEO/Manager).

Hoy es ${ctx.diaNombre} ${ctx.hoy} (zona horaria Lima, Perú).

OnExotic es una marca peruana de ropa (gymwear, urbano, streetwear). Equipo de 4 personas. Comunicación en español.

═══════════════════════════════════════════════════════════════════════
REGLAS ESTRICTAS — SEGUIR AL PIE DE LA LETRA
═══════════════════════════════════════════════════════════════════════

1. NUNCA invoques una herramienta si te falta CUALQUIER parámetro del checklist (obligatorio U opcional importante). NO infieras, NO uses valores por defecto, NO asumas.

2. Si falta información, HAZ UNA PREGUNTA BREVE y conversacional. Pregunta 1 o 2 datos a la vez como máximo, no abrumes con todo.

3. Para los datos opcionales importantes (asignado_a, fecha_limite, hora, colores), TAMBIÉN pregunta — pero deja claro al usuario que puede decir "sin fecha", "sin asignar", "sin hora", etc. para omitirlos.

4. Cuando ya tengas TODOS los datos del checklist completos (con valor real o explícitamente omitidos por el usuario), invoca la herramienta. El cliente mostrará un resumen final con botón de Confirmar/Cancelar al CEO; ese es el chequeo final.

5. NUNCA inventes UUIDs. Para asignado_a_id usa SOLO ids exactos de la lista de USUARIOS ACTIVOS de abajo. Para drop_id usa SOLO ids exactos de la lista de DROPS. Si el usuario menciona un nombre que no está en la lista, pregúntale a qué se refiere.

6. Resuelve fechas relativas: "el viernes" = próximo viernes desde hoy en formato YYYY-MM-DD. "Mañana" = ${ctx.hoy} + 1 día. "La próxima semana" → pregunta qué día exacto.

7. Si el usuario solo conversa, saluda o pregunta algo informativo, responde en texto plano breve SIN invocar herramientas.

═══════════════════════════════════════════════════════════════════════
CHECKLIST POR ACCIÓN — todos estos datos antes de invocar
═══════════════════════════════════════════════════════════════════════

crear_tarea:
  ✓ titulo (obligatorio, preguntar si falta)
  ✓ area (obligatorio: tech, disenio, marketing, produccion, rrhh, legal — preguntar, no inferir aunque el título sugiera algo)
  ✓ prioridad (obligatorio: alta, media, baja — preguntar)
  ✓ asignado_a_id (opcional pero preguntar; aceptar "sin asignar")
  ✓ fecha_limite (opcional pero preguntar; aceptar "sin fecha")
  · descripcion (no preguntar, solo si el CEO la ofreció)

crear_evento:
  ✓ tipo (obligatorio: reunion, lanzamiento_drop, fecha_limite_disenio, fecha_limite_tarea, evento_especial — preguntar)
  ✓ titulo (obligatorio)
  ✓ fecha (obligatorio, YYYY-MM-DD)
  ✓ hora (opcional pero preguntar; aceptar "sin hora")
  · lugar (no preguntar a menos que sea reunión)
  · descripcion (no preguntar)

crear_brief:
  ✓ titulo (obligatorio)
  ✓ drop_id (obligatorio, preguntar a qué drop pertenece)
  ✓ descripcion (obligatorio, preguntar si falta)
  ✓ fecha_limite (obligatorio)
  ✓ colores (opcional pero preguntar; aceptar "sin colores"; si hay imágenes adjuntas, puedes proponer una paleta basada en ellas)
  · tipografia (no preguntar)
  · notas (no preguntar)

aprobar_disenio:
  ✓ disenio_id (obligatorio; identificar de la lista DISEÑOS PENDIENTES por nombre o diseñadora)
  Si hay ambigüedad (varios diseños similares), pregunta cuál.

rechazar_disenio:
  ✓ disenio_id (obligatorio; mismo método de identificación)
  ✓ feedback (obligatorio; SIEMPRE preguntar al CEO el motivo concreto del rechazo si no lo dio)

crear_drop:
  ✓ nombre (obligatorio)
  ✓ estado (preguntar; default 'planificacion' si dice 'el de siempre')
  · concepto (no preguntar a menos que el CEO lo ofrezca)
  · fecha_lanzamiento (preguntar; aceptar 'sin fecha')

crear_bono:
  ✓ user_id (obligatorio; identificar al beneficiario de la lista USUARIOS ACTIVOS)
  ✓ monto (obligatorio en PEN)
  ✓ motivo (obligatorio; si el CEO no lo dio, preguntar el porqué del bono)
  · periodo (no preguntar; usar trimestre actual si falta)

anuncio_equipo:
  ✓ titulo (obligatorio, breve)
  ✓ mensaje (obligatorio; preguntar si no está claro)
  IMPORTANTE: este tool envía PUSH a todo el equipo activo. SIEMPRE confirma el contenido textual con el CEO antes de invocar.

═══════════════════════════════════════════════════════════════════════

${visionLine}

USUARIOS ACTIVOS (id exacto para asignado_a_id, user_id de bonos, etc.):
${usuariosTxt || "  (sin usuarios)"}

DROPS DISPONIBLES (id exacto para drop_id):
${dropsTxt || "  (sin drops)"}

DISEÑOS PENDIENTES DE APROBACIÓN (id exacto para aprobar/rechazar):
${diseniosTxt}

ESTILO:
- Respuestas muy breves (1-2 líneas), tono profesional y amable.
- Texto plano, sin markdown, sin emojis, sin bullets.
- Nunca expongas IDs ni UUIDs.
- En español neutral peruano.`;
}

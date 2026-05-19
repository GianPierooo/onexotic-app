# Módulo: Asistente IA
> Referencia visual: leer mockups/Asistente.html

---

## Archivos a crear
```
lib/modules/ai_asistente/
├── providers/
│   ├── ai_provider.dart
│   └── ai_context_builder.dart
├── screens/
│   └── ai_screen.dart
└── widgets/
    ├── mensaje_bubble.dart
    ├── input_chat.dart
    ├── sugerencias_chips.dart
    └── typing_indicator.dart
```

---

## Arquitectura — MUY IMPORTANTE
```
Flutter (input usuario)
  ↓
Supabase Edge Function: /functions/v1/ai-chat
  ↓ verifica JWT
  ↓ obtiene rol del usuario
  ↓ consulta datos permitidos según rol (RLS)
  ↓ construye context_data
  ↓ llama Claude API (max_tokens: 150)
  ↓ retorna texto plano
  ↓
Flutter muestra respuesta en bubble
```

**La API key de Claude NUNCA va en Flutter — solo en la Edge Function.**

---

## Pantalla (replicar mockups/Asistente.html)

### Header
- Ícono robot izquierda con punto verde (activo)
- Título "OnExotic AI"
- Badge "BETA" naranja
- Subtítulo "Asistente interno · activo" en #888888
- Ícono trash derecha → limpiar conversación con confirmación

### Área de conversación
- Fondo: AppColors.background
- Separador de fecha: "HOY · HH:MM AM" centrado en #555555
- Scroll automático al último mensaje

### MensajeBubble — Usuario (derecha)
- Fondo: #FF4500 con opacidad 20% → Color(0x33FF4500)
- Borde: #FF4500 con opacidad 40%
- Texto: blanco
- Timestamp: HH:mm en #555555 abajo izquierda del bubble

### MensajeBubble — IA (izquierda)
- Fondo: AppColors.surface2 (#1E1E1E)
- Borde: AppColors.border (#2A2A2A)
- Ícono robot pequeño arriba izquierda
- Texto: blanco — SOLO TEXTO PLANO, sin markdown, sin chips, sin listas
- Timestamp: HH:mm en #555555

### TypingIndicator (mientras IA procesa)
- Bubble izquierdo con 3 puntos animados "···"
- Animación: fade in/out alternado con flutter_animate

### SugerenciasChips (bajo el área de chat)
Estas SÍ son chips en la UI — no son respuestas de la IA:
- CEO: "Resumen del día" · "Stock crítico" · "Ventas semana"
- Diseñadora: "Mis briefs" · "Próxima reunión" · "Ideas paletas"
- RRHH: "Asistencia hoy" · "Quién faltó" · "Bonos pendientes"
- Al tocar: envía como mensaje del usuario

### InputChat (fijo abajo)
- Fondo: AppColors.surface (#141414)
- Borde superior: AppColors.border
- Campo texto "Pregunta algo..." sobre #1E1E1E
- Botón enviar: circular #FF4500 con ícono flecha

---

## REGLAS CRÍTICAS DE LA IA — NO NEGOCIABLES
1. Respuestas SOLO texto plano
2. Sin markdown, chips, badges, bullets ni listas
3. Sin botones de acción dentro de los bubbles
4. Máximo 2–3 líneas por respuesta
5. max_tokens: 150 siempre
6. Si no tiene datos: "No tengo esa información disponible."

---

## Llamada a la Edge Function
```dart
final response = await supabase.functions.invoke(
  'ai-chat',
  body: {
    'mensaje': mensajeUsuario,
    'historial': historialConversacion, // últimos 6 mensajes
  },
);
final respuesta = response.data['respuesta'] as String;
```

---

## Historial de conversación
- Guardar en memoria local (List<Map> en el provider)
- NO guardar en Supabase
- Al limpiar conversación: confirmar con dialog
- Al cerrar sesión: se borra automáticamente
- Enviar últimos 6 mensajes a la Edge Function para contexto

---

## Supabase Edge Function (referencia)
```typescript
// supabase/functions/ai-chat/index.ts
// 1. Verificar JWT → obtener user_id y rol
// 2. Según rol, consultar datos permitidos
// 3. Construir system prompt del rol con context_data
// 4. Llamar Anthropic API con max_tokens: 150
// 5. Retornar { respuesta: string }
```
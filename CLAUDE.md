# ONEXOTIC — App Interna de Gestión
> Lee este archivo completo antes de escribir cualquier línea de código.
> Los mockups HTML de referencia visual están en: /mockups/
> Los CLAUDE.md de cada módulo están en: /lib/modules/{modulo}/CLAUDE.md

---

## 1. CONTEXTO DEL NEGOCIO

OnExotic es una marca peruana de ropa (gymwear · urbano · streetwear) fundada en 2025.
Opera por sistema de drops limitados: EXOTIC0 → Ñ → Drop 003 → ...
Canales de venta: Instagram, TikTok, Facebook, WhatsApp Business.
Web: onexotic.shop

### Equipo actual
| Persona      | Rol                        | Horario       |
|-------------|----------------------------|---------------|
| Gian Piero  | CEO · Tech · Ventas        | 9:00–19:00    |
| Luis Felipe | CEO · Producción           | 9:00–19:00    |
| Camila      | Diseñadora                 | 12:00–18:00   |
| Andrea      | RRHH                       | 12:00–18:00   |

### Flujo de diseños
Brief (CEOs) → Fecha límite → Propuesta (diseñadora) → Revisión CEOs → Aprobación → Producción

### Sistema de drops
Cada drop tiene: nombre · concepto · fecha de lanzamiento · estado · prendas asociadas

---

## 2. QUÉ ES ESTA APP

App móvil interna para el equipo OnExotic. NO es para clientes.
Flutter: web + iOS + Android desde un solo codebase.
Gestiona: inventario, diseños, tareas, asistencia, calendario, equipo y asistente IA.

---

## 3. STACK TÉCNICO

| Capa           | Tecnología                              |
|----------------|----------------------------------------|
| Mobile/Web     | Flutter (Dart) — latest stable         |
| Backend        | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| State          | Riverpod v2 con anotaciones @riverpod  |
| Navegación     | go_router con guards por rol           |
| UI             | shadcn_ui                              |
| Animaciones    | flutter_animate (200–300ms, suaves)    |
| Tipografía     | google_fonts (Space Grotesk + Inter)   |
| Gráficas       | fl_chart                               |
| Imágenes       | cached_network_image                   |
| Archivos       | image_picker                           |
| Fechas         | intl + timeago (español)               |
| Env vars       | flutter_dotenv                         |

### pubspec.yaml completo
```yaml
name: onexotic_app
description: App interna de gestión OnExotic

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  supabase_flutter: ^2.5.0
  go_router: ^14.0.0
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  shadcn_ui: ^0.14.0
  fl_chart: ^0.68.0
  cached_network_image: ^3.3.1
  image_picker: ^1.1.2
  timeago: ^3.6.1
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.3
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.13

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/images/
    - assets/fonts/
```

---

## 4. ESTRUCTURA DE CARPETAS

```
onexotic_app/
├── CLAUDE.md                        ← este archivo (raíz)
├── .env                             ← NUNCA commitear
├── .gitignore
├── pubspec.yaml
├── mockups/                         ← HTMLs de referencia visual (NO modificar)
│   ├── Login.html
│   ├── Dashboard.html
│   ├── Asistencia.html
│   ├── Tareas.html
│   ├── Calendario.html
│   ├── Disenios.html
│   ├── Brief.html
│   ├── Inventario.html
│   ├── Equipo.html
│   ├── Asistente.html
│   ├── Notificaciones.html
│   ├── Perfil.html
│   └── Dashboard-Disenadora.html
├── docs/
│   ├── setup.md
│   ├── db_schema.md
│   └── roles_permisos.md
├── assets/
│   ├── images/
│   └── fonts/
└── lib/
    ├── main.dart
    ├── core/
    │   ├── auth/
    │   │   ├── auth_provider.dart
    │   │   ├── auth_service.dart
    │   │   └── role_guard.dart
    │   ├── router/
    │   │   └── app_router.dart
    │   ├── theme/
    │   │   ├── app_theme.dart
    │   │   ├── app_colors.dart
    │   │   └── app_typography.dart
    │   ├── supabase/
    │   │   └── supabase_client.dart
    │   └── constants/
    │       ├── app_constants.dart
    │       └── roles.dart
    ├── modules/
    │   ├── login/
    │   │   ├── providers/
    │   │   └── screens/
    │   ├── dashboard/
    │   │   ├── CLAUDE.md
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── inventario/
    │   │   ├── CLAUDE.md
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── disenios/
    │   │   ├── CLAUDE.md
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── tareas/
    │   │   ├── CLAUDE.md
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── asistencia/
    │   │   ├── CLAUDE.md
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── calendario/
    │   │   ├── CLAUDE.md
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── equipo/
    │   │   ├── CLAUDE.md
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── notificaciones/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── perfil/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   └── ai_asistente/
    │       ├── CLAUDE.md
    │       ├── providers/
    │       ├── screens/
    │       └── widgets/
    └── shared/
        ├── widgets/
        │   ├── app_button.dart
        │   ├── app_card.dart
        │   ├── app_input.dart
        │   ├── loading_widget.dart
        │   ├── empty_state.dart
        │   └── error_widget.dart
        ├── utils/
        │   ├── date_formatter.dart
        │   ├── validators.dart
        │   └── extensions.dart
        └── hooks/
            └── use_supabase_stream.dart
```

---

## 5. TEMA VISUAL

> Referencia principal: mockups/Login.html y mockups/Dashboard.html
> El estilo es minimal oscuro — referencias: Linear, Vercel, Arc

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Fondos
  static const background  = Color(0xFF0A0A0A);
  static const surface     = Color(0xFF141414);
  static const surface2    = Color(0xFF1E1E1E);
  static const surface3    = Color(0xFF252525);
  // Bordes
  static const border      = Color(0xFF2A2A2A);
  static const borderHover = Color(0xFF3A3A3A);
  // Textos
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF888888);
  static const textTertiary  = Color(0xFF555555);
  // Marca OnExotic
  static const accent        = Color(0xFFFF4500);
  static const accentHover   = Color(0xFFFF5A1F);
  // Semánticos
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);
  // Áreas de tareas
  static const areaTech       = Color(0xFF3B82F6);
  static const areaDiseño     = Color(0xFFA78BFA);
  static const areaMarketing  = Color(0xFFF97316);
  static const areaProduccion = Color(0xFF22C55E);
  static const areaRRHH       = Color(0xFF38BDF8);
  static const areaLegal      = Color(0xFFEF4444);
}
```

### Reglas visuales obligatorias
- Tema oscuro por defecto, usuario puede cambiar a claro en Perfil
- Tipografía: Space Grotesk (headings w500/600) · Inter (body w400/500)
- Border radius: 8px elementos · 12px cards · 16px modales/sheets
- Sin sombras — usar color y borde para elevación
- Animaciones: 200–300ms, curva easeOut con flutter_animate
- Bottom navigation: 5 ítems siempre visibles, nunca cortados
- CEO nav: Inicio · Asistencia · Tareas · Equipo · Perfil
- Diseñadora nav: Inicio · Mis Diseños · Calendario · IA · Perfil
- Botón flotante "+": siempre color #FF4500, circular, bottom right

---

## 6. BASE DE DATOS SUPABASE

### users
```sql
id           uuid PK (ref auth.users)
nombre       text NOT NULL
email        text NOT NULL
rol          text CHECK (rol IN ('ceo','manager','disenadora','rrhh','produccion'))
avatar_url   text
horario      text        -- '12:00-18:00'
tema         text DEFAULT 'dark' CHECK (tema IN ('dark','light'))
activo       boolean DEFAULT true
created_at   timestamptz DEFAULT now()
```

### drops
```sql
id                 uuid PK DEFAULT gen_random_uuid()
nombre             text NOT NULL   -- 'EXOTIC0', 'Ñ', 'Drop 003'
concepto           text
fecha_lanzamiento  date
estado             text CHECK (estado IN ('planificacion','produccion','lanzado','agotado'))
created_at         timestamptz DEFAULT now()
```

### productos
```sql
id            uuid PK DEFAULT gen_random_uuid()
nombre        text NOT NULL
tipo          text CHECK (tipo IN ('polo','short','pantalon','polera','accesorio'))
drop_id       uuid FK drops(id)
talla         text CHECK (talla IN ('XS','S','M','L','XL','XXL'))
color         text
stock         integer DEFAULT 0
stock_minimo  integer DEFAULT 5
costo         decimal(10,2)
precio_venta  decimal(10,2)
estado        text CHECK (estado IN ('activo','agotado','descontinuado'))
imagen_url    text
sku           text UNIQUE   -- formato: EX-HD-001
created_at    timestamptz DEFAULT now()
```

### asistencia
```sql
id            uuid PK DEFAULT gen_random_uuid()
user_id       uuid FK users(id)
fecha         date NOT NULL
presente      boolean DEFAULT false
hora_entrada  timestamptz
nota          text
reunion_tipo  text DEFAULT 'diaria' CHECK (reunion_tipo IN ('diaria','semanal','extraordinaria'))
created_at    timestamptz DEFAULT now()
UNIQUE(user_id, fecha, reunion_tipo)
```

### disenios
```sql
id             uuid PK DEFAULT gen_random_uuid()
titulo         text NOT NULL
drop_id        uuid FK drops(id)
disenadora_id  uuid FK users(id)
estado         text CHECK (estado IN ('brief','proceso','revision','aprobado','rechazado'))
archivo_url    text
thumbnail_url  text
aprobado_por   uuid FK users(id)
fecha_limite   date
feedback       text
version        integer DEFAULT 1
created_at     timestamptz DEFAULT now()
updated_at     timestamptz DEFAULT now()
```

### briefs
```sql
id                 uuid PK DEFAULT gen_random_uuid()
disenio_id         uuid FK disenios(id)
titulo             text NOT NULL
descripcion        text
referencias_urls   text[]
colores            text[]
tipografia         text
notas_adicionales  text
fecha_limite       date
creado_por         uuid FK users(id)
created_at         timestamptz DEFAULT now()
```

### tareas
```sql
id           uuid PK DEFAULT gen_random_uuid()
titulo       text NOT NULL
descripcion  text
area         text CHECK (area IN ('tech','disenio','marketing','produccion','rrhh','legal'))
prioridad    text CHECK (prioridad IN ('alta','media','baja'))
asignado_a   uuid FK users(id)
completado   boolean DEFAULT false
fecha_limite date
created_at   timestamptz DEFAULT now()
updated_at   timestamptz DEFAULT now()
```

### notificaciones
```sql
id          uuid PK DEFAULT gen_random_uuid()
user_id     uuid FK users(id)
titulo      text NOT NULL
mensaje     text
tipo        text CHECK (tipo IN ('asistencia','disenio','tarea','inventario','bono','sistema'))
leido       boolean DEFAULT false
created_at  timestamptz DEFAULT now()
```

### bonos
```sql
id            uuid PK DEFAULT gen_random_uuid()
user_id       uuid FK users(id)
monto         decimal(10,2)
motivo        text
periodo       text   -- 'Q1-2025'
aprobado_por  uuid FK users(id)
created_at    timestamptz DEFAULT now()
```

### proveedores
```sql
id          uuid PK DEFAULT gen_random_uuid()
nombre      text NOT NULL
contacto    text
telefono    text
tipo        text   -- 'tela','estampado','confeccion','packaging'
rating      integer CHECK (rating BETWEEN 1 AND 5)
notas       text
activo      boolean DEFAULT true
created_at  timestamptz DEFAULT now()
```

> RLS activado en TODAS las tablas sin excepción.

---

## 7. ROLES Y PERMISOS

| Módulo              | CEO | Diseñadora      | RRHH        | Producción      |
|---------------------|-----|-----------------|-------------|-----------------|
| Dashboard completo  | ✅  | ❌ vista propia  | Parcial     | Parcial         |
| Inventario CRUD     | ✅  | ❌              | ❌          | ✅              |
| Costos/márgenes     | ✅  | ❌              | ❌          | ❌              |
| Diseños CRUD        | ✅  | Solo propios    | ❌          | Ver aprobados   |
| Aprobar diseños     | ✅  | ❌              | ❌          | ❌              |
| Tareas CRUD         | ✅  | Solo propias    | Ver+editar  | Solo propias    |
| Asistencia CRUD     | ✅  | Solo propia     | ✅ todos    | Solo propia     |
| Equipo CRUD         | ✅  | ❌              | ✅          | ❌              |
| Bonos               | ✅  | Ver propios     | ✅          | Ver propios     |
| Proveedores         | ✅  | ❌              | ❌          | ✅              |
| Analíticas          | ✅  | ❌              | ❌          | ❌              |

---

## 8. ASISTENTE IA

### Configuración técnica
- Modelo: claude-sonnet-4-20250514
- max_tokens: 150 — NUNCA superar, controla costos
- Llamada SIEMPRE desde Supabase Edge Function — NUNCA desde Flutter
- API key de Claude NUNCA en el cliente Flutter

### Reglas de respuesta — sin excepciones
- Solo texto plano
- Sin markdown, chips, bullets, listas ni badges
- Sin botones de acción dentro del chat
- Máximo 2–3 líneas
- Solo responde lo que se preguntó
- Si no tiene datos: "No tengo esa información disponible."

### System prompts por rol

**CEO:**
```
Eres el asistente de OnExotic. Solo texto plano, máximo 3 líneas, sin markdown.
Responde solo lo que pregunten. Acceso completo a todos los datos.
Contexto: {context_data}
```

**Diseñadora:**
```
Eres el asistente de diseño de OnExotic. Solo texto plano, máximo 3 líneas, sin markdown.
SOLO respondes sobre: tus briefs, fechas límite, tu calendario, diseño, tendencias, paletas.
NO accedes a: stock, costos, datos de otros, ventas. Si preguntan: "No tengo acceso a esa información."
Contexto: {context_data_limitado}
```

**RRHH:**
```
Eres el asistente de RRHH de OnExotic. Solo texto plano, máximo 3 líneas, sin markdown.
SOLO respondes sobre: asistencia, reuniones, perfiles del equipo, bonos.
NO accedes a: inventario, costos, diseños internos, ventas.
Contexto: {context_data_limitado}
```

**Producción:**
```
Eres el asistente de producción de OnExotic. Solo texto plano, máximo 3 líneas, sin markdown.
SOLO respondes sobre: stock, drops, proveedores, tus tareas, tu calendario.
NO accedes a: márgenes, datos del equipo, diseños internos, ventas totales.
Contexto: {context_data_limitado}
```

---

## 9. CONVENCIONES DE CÓDIGO

### Nombrado
- Archivos: snake_case → `inventario_screen.dart`
- Clases: PascalCase → `InventarioScreen`
- Variables negocio: español → `stockActual`, `fechaLimite`, `disenioActivo`
- Variables técnicas: inglés → `isLoading`, `hasError`, `onPressed`
- Providers: sufijo Provider → `inventarioProvider`
- Models: sin sufijo → `Producto`, `Tarea`, `Disenio`

### Reglas obligatorias
- Siempre `const` donde sea posible
- Siempre manejar 4 estados: loading · error · empty · data
- Nunca hardcodear API keys — usar flutter_dotenv
- No `print()` en producción
- Lógica NUNCA directamente en widgets — siempre en providers

### Patrón provider estándar
```dart
@riverpod
Future<List<Producto>> inventario(InventarioRef ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
    .from('productos')
    .select()
    .eq('estado', 'activo')
    .order('created_at', ascending: false);
  return data.map((e) => Producto.fromJson(e)).toList();
}
```

### Patrón pantalla estándar
```dart
class InventarioScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productos = ref.watch(inventarioProvider);
    return productos.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidget(message: e.toString()),
      data: (data) => data.isEmpty
        ? const EmptyState(message: 'No hay productos')
        : ProductosList(productos: data),
    );
  }
}
```

---

## 10. CÓMO USAR LOS MOCKUPS

Los HTMLs en /mockups/ son la referencia visual exacta aprobada.
Cuando construyas cualquier pantalla:
1. Lee el HTML del mockup correspondiente
2. Extrae: estructura, colores, espaciados, componentes
3. Replica en Flutter con shadcn_ui y AppColors
4. Los datos en el HTML son solo ilustrativos

Prompt correcto para Claude Code:
```
Lee mockups/Asistencia.html y lib/modules/asistencia/CLAUDE.md.
Construye AsistenciaScreen replicando exactamente el diseño visual.
```

---

## 11. ORDEN DE CONSTRUCCIÓN MVP

### Fase 1 — Base
1. core/theme/ — colores, tipografía, tema oscuro/claro
2. core/auth/ — login Supabase, sesión, roles
3. core/router/ — go_router con guards
4. shared/widgets/ — AppButton, AppCard, AppInput, LoadingWidget, EmptyState, ErrorWidget

### Fase 2 — Pantallas principales
5. modules/login/
6. modules/dashboard/
7. modules/asistencia/
8. modules/tareas/
9. modules/calendario/
10. modules/disenios/

### Fase 3 — Operaciones
11. modules/inventario/
12. modules/equipo/
13. modules/notificaciones/
14. modules/perfil/

### Fase 4 — Diferencial
15. modules/ai_asistente/
16. Analíticas con fl_chart
17. Proveedores

---

## 12. VARIABLES DE ENTORNO

Archivo .env en la raíz — NUNCA commitear, está en .gitignore:
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```
La CLAUDE_API_KEY va SOLO en Supabase Edge Functions, nunca aquí.

---

## 13. COMANDOS FRECUENTES

```bash
# Correr en web
flutter run -d chrome

# Correr en móvil
flutter run

# Generar código Riverpod
dart run build_runner watch --delete-conflicting-outputs

# Build web producción
flutter build web --release

# Generar tipos Supabase
supabase gen types dart --local > lib/core/supabase/database_types.dart
```

---

## 14. CHECKLIST ANTES DE CADA COMMIT

- [ ] Sin API keys hardcodeadas
- [ ] Providers manejan loading/error/empty/data
- [ ] RLS activado en tablas nuevas
- [ ] Formularios con validación
- [ ] Widgets usan const donde aplica
- [ ] Sin print() en producción
- [ ] Probado en web Y móvil

---

## 15. NOTAS DEL NEGOCIO

- Nombre: ONEXOTIC en logo · OnExotic en texto corrido
- Horario diseñadora Camila: SIEMPRE 12:00–18:00 (nunca otro valor)
- Drops: EXOTIC0 → Ñ → Drop 003 → Drop 004...
- Reuniones: diarias a las 9:00 AM
- Comunicación del equipo: Discord
- Registro INDECOPI: pendiente y urgente
- Email corporativo onexotic.shop: pendiente

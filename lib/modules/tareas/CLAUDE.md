# Módulo: Tareas
> Referencia visual: leer mockups/Tareas.html

---

## Archivos a crear
```
lib/modules/tareas/
├── models/
│   └── tarea.dart
├── providers/
│   └── tareas_provider.dart
├── screens/
│   ├── tareas_screen.dart
│   └── tarea_detail_screen.dart
└── widgets/
    ├── tarea_item.dart
    ├── filtro_pills.dart
    ├── prioridad_badge.dart
    └── area_badge.dart
```

---

## Modelo
```dart
class Tarea {
  final String id;
  final String titulo;
  final String? descripcion;
  final String area; // tech|disenio|marketing|produccion|rrhh|legal
  final String prioridad; // alta|media|baja
  final String? asignadoA;
  final bool completado;
  final DateTime? fechaLimite;
  final DateTime createdAt;
}
```

---

## Pantalla principal (replicar mockups/Tareas.html)

### Header
- Título "Tareas"
- Subtítulo: "{total} pendientes · {urgentes} urgentes" en #888888
- Ícono filtro arriba derecha

### Filtros horizontales scrolleables (pills)
Fila 1 — Estado: Todas · Mis tareas · Completadas
Fila 2 — Área: Tech · Diseño · Marketing · Producción · RRHH · Legal
- Pill activo: fondo #FF4500, texto blanco
- Pill inactivo: fondo #1E1E1E, texto #888888, borde #2A2A2A

### Lista de tareas
Cada TareaItem sobre card #141414:
- Checkbox circular izquierda (borde #2A2A2A, check #FF4500 al completar)
- Título en blanco
- Fila inferior: AreaBadge + PrioridadBadge + fecha límite derecha
- Al completar: animación suave, tarea baja al final con opacidad reducida
- Al tocar: navega a detalle

### Ordenamiento
- Primero: no completadas ordenadas por prioridad (alta → media → baja)
- Luego: completadas al final, opacity 0.5

### Botón flotante "+"
- Color #FF4500, circular, bottom right
- Solo visible para CEO/Manager
- Abre modal para crear tarea

---

## Colores por área
```dart
static const Map<String, Color> areaColors = {
  'tech':       Color(0xFF3B82F6),  // azul
  'disenio':    Color(0xFFA78BFA),  // púrpura
  'marketing':  Color(0xFFF97316),  // naranja
  'produccion': Color(0xFF22C55E),  // verde
  'rrhh':       Color(0xFF38BDF8),  // celeste
  'legal':      Color(0xFFEF4444),  // rojo
};
```

## Colores por prioridad
```dart
// Badge: fondo con 20% opacidad, texto al 100%
'alta':  Color(0xFFEF4444)  // rojo
'media': Color(0xFFF59E0B)  // amarillo
'baja':  Color(0xFF22C55E)  // verde
```

---

## Permisos por rol
- CEO / Manager: ven todas, CRUD completo, pueden asignar
- Diseñadora / Producción: solo ven las suyas (asignado_a = user_id)
- RRHH: ve todas, puede editar estado pero no eliminar

---

## Pantalla detalle de tarea
- Header con flecha atrás + título
- Título completo
- Descripción
- AreaBadge + PrioridadBadge
- Asignado a: avatar + nombre
- Fecha límite
- Botón "Marcar como completada" #FF4500
- Botón "Editar" (solo CEO/Manager)

---

## Provider
```dart
@riverpod
Future<List<Tarea>> tareas(TareasRef ref, {
  String? area,
  String? prioridad,
  bool? soloMias,
}) async {
  var query = supabase.from('tareas').select();
  if (area != null) query = query.eq('area', area);
  if (prioridad != null) query = query.eq('prioridad', prioridad);
  if (soloMias == true) query = query.eq('asignado_a', currentUserId);
  return query.order('created_at', ascending: false);
}
```
# Módulo: Calendario
> Referencia visual: leer mockups/Calendario.html

---

## Archivos a crear
```
lib/modules/calendario/
├── providers/
│   └── calendario_provider.dart
├── screens/
│   └── calendario_screen.dart
└── widgets/
    ├── mes_grid.dart
    ├── dia_cell.dart
    ├── eventos_sheet.dart
    ├── evento_item.dart
    └── leyenda_colores.dart
```

---

## Modelo de evento unificado
```dart
class EventoCalendario {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final TimeOfDay? hora;
  final String tipo; // 'drop' | 'reunion' | 'tarea' | 'disenio'
  final Color color;
}
```

---

## Pantalla (replicar mockups/Calendario.html)

### Header
- Flecha izquierda · "Mayo 2026" · Flecha derecha
- Toggle "Mes / Semana" arriba derecha

### Vista mensual (grid)
- 7 columnas L·M·M·J·V·S·D
- Fondo: AppColors.background
- Día de hoy: círculo #FF4500 con número blanco
- Día seleccionado: fondo #1E1E1E redondeado
- Puntos de eventos debajo del número (máximo 3, si hay más: "···")
- Al tocar un día: abre EventosSheet

### EventosSheet (bottom sheet)
- Drag handle arriba (barra gris centrada) — OBLIGATORIO para que el usuario sepa que puede arrastrar
- Título: "Hoy · Vie 16 mayo" + "{n} eventos"
- Botón "+" arriba derecha para agregar evento
- Lista de eventos del día seleccionado:
  · Hora izquierda en #888888
  · Línea vertical de color del tipo
  · Título en blanco
  · Descripción corta en #888888
  · Flecha derecha →
- EmptyState si no hay eventos: "Sin eventos este día"

### Leyenda (siempre visible al fondo)
- Punto naranja #FF4500 = Drop
- Punto azul #3B82F6 = Reunión
- Punto amarillo #F59E0B = Tarea
- Punto verde #22C55E = Diseño

---

## Fuentes de datos (todo fusionado)

```dart
@riverpod
Future<Map<DateTime, List<EventoCalendario>>> calendarioEventos(
  CalendarioEventosRef ref,
  DateTime mes,
) async {
  // 1. Drops → fecha_lanzamiento → color #FF4500
  // 2. Asistencia/reuniones → fecha → color #3B82F6
  // 3. Tareas → fecha_limite WHERE completado=false → color #F59E0B
  // 4. Diseños → fecha_limite → color #22C55E
  // Fusionar todo en un Map<DateTime, List<EventoCalendario>>
}
```

---

## Personalización por rol
- CEO: todos los eventos de todos
- Diseñadora: sus reuniones + sus fechas límite de diseños + drops
- RRHH: reuniones del equipo + asistencia
- Producción: drops + sus tareas

---

## Vista semanal (toggle)
- 7 columnas con horas en eje Y (8:00 AM – 8:00 PM)
- Eventos como bloques de color en su hora
- Scroll vertical para ver todas las horas
# Módulo: Dashboard
> Referencia visual: leer mockups/Dashboard.html (CEO) y mockups/Dashboard-Disenadora.html (diseñadora)

---

## Archivos a crear
```
lib/modules/dashboard/
├── providers/
│   └── dashboard_provider.dart
├── screens/
│   └── dashboard_screen.dart
└── widgets/
    ├── metric_card.dart
    ├── actividad_reciente_list.dart
    ├── actividad_reciente_item.dart
    ├── acceso_rapido_ia.dart
    └── proximo_drop_banner.dart
```

---

## Comportamiento por rol

### CEO (replicar mockups/Dashboard.html)
- Header: "Buenos días/tardes, {nombre} 👋" + fecha de hoy + ícono notificaciones con badge
- Grid 2x2 de MetricCards
- Sección "Actividad reciente" con máximo 3 items
- Card "Acceso rápido — Asistente IA" SIEMPRE completamente visible, nunca cortada

### Diseñadora (replicar mockups/Dashboard-Disenadora.html)
- Header: "Buenos días/tardes, {nombre} 👋" + horario "Tu turno: 12:00–18:00"
- Sección "Mis briefs activos" — scroll horizontal con cards de diseños propios
- Sección "Mis tareas del día" — solo las suyas
- Sección "Próximas reuniones" — con botón "Marcar" si la reunión es ahora
- Card "Asistente IA" limitada al rol

### RRHH
- Asistencia del equipo hoy
- Tareas asignadas a él/ella
- Próximas reuniones

### Producción
- Stock crítico (productos bajo stock_minimo)
- Drops activos
- Tareas asignadas

---

## MetricCard — 4 cards para CEO

### Card 1: Stock crítico
- Ícono: caja/paquete
- Número: COUNT productos WHERE stock <= stock_minimo AND estado = 'activo'
- Color número: #EF4444 (rojo)
- Label: "Stock crítico"
- Badge top-right: "SKUs"

### Card 2: Tareas pendientes
- Ícono: checklist
- Número: COUNT tareas WHERE completado = false
- Color número: #FF4500 (acento)
- Label: "Tareas pendientes"
- Badge top-right: "hoy"

### Card 3: Asistencia hoy
- Ícono: usuarios
- Número: "{presentes}/{total}" — ej: "3/4"
- Color número: #22C55E (verde)
- Label: "Asistencia hoy"
- Badge top-right: "equipo"

### Card 4: Próximo drop
- Ícono: calendario
- Número: días restantes al próximo drop
- Color número: #3B82F6 (azul)
- Label: "Próximo drop"
- Badge top-right: fecha del drop (ej: "JUN 28")

---

## Actividad reciente
- Query: últimos 3 eventos de notificaciones ordenados por created_at DESC
- Cada item: avatar circular + título + descripción corta + timeago
- Botón "Ver todo" → navega a /notificaciones
- Fondo: AppColors.surface (#141414)

---

## Card Acceso rápido IA
- Fondo: degradado sutil de #FF4500/30 a #1E1E1E
- Ícono robot con badge "BETA"
- Título: "Asistente IA"
- Subtítulo: "Pregúntame cualquier cosa sobre OnExotic"
- Flecha →
- Al tocar: navega a /ai
- NUNCA cortada — completamente visible sin scroll

---

## Saludo dinámico
```dart
String getSaludo() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'Buenos días';
  if (hora < 19) return 'Buenas tardes';
  return 'Buenas noches';
}
```

---

## Bottom navigation CEO
Inicio(activo) · Asistencia · Tareas · Equipo · Perfil

## Bottom navigation Diseñadora
Inicio(activo) · Mis Diseños · Calendario · IA · Perfil
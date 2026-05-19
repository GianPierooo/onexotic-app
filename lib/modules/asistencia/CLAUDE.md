# Módulo: Asistencia
> Referencia visual: leer mockups/Asistencia.html

---

## Archivos a crear
```
lib/modules/asistencia/
├── models/
│   └── registro_asistencia.dart
├── providers/
│   └── asistencia_provider.dart
├── screens/
│   ├── asistencia_screen.dart
│   └── historial_screen.dart
└── widgets/
    ├── reunion_card.dart
    ├── miembro_asistencia_item.dart
    ├── mini_calendario_semanal.dart
    └── historial_item.dart
```

---

## Modelo
```dart
class RegistroAsistencia {
  final String id;
  final String userId;
  final DateTime fecha;
  final bool presente;
  final DateTime? horaEntrada;
  final String? nota;
  final String reunionTipo; // 'diaria' | 'semanal' | 'extraordinaria'
}
```

---

## Pantalla principal (replicar mockups/Asistencia.html)

### Header
- Título "Asistencia" en blanco
- Subtítulo: fecha de hoy en #888888
- Botón "+" arriba derecha para crear reunión (solo CEO/RRHH)

### Card "Reunión de hoy"
- Título: "Reunión diaria" + badge "EN CURSO" verde si es ahora
- Horario y lugar: "9:00 AM · Showroom"
- Contador: "2/4" arriba derecha
- Lista de miembros con estado:
  · Avatar circular con iniciales + nombre + rol
  · Badge PRESENTE: fondo #22C55E/20, texto #22C55E, ícono check
  · Badge AUSENTE: fondo #EF4444/20, texto #EF4444, ícono X
  · Badge PENDIENTE: fondo #F59E0B/20, texto #F59E0B, ícono reloj
- Botón "Marcar mi asistencia" full width #FF4500
  · Visible solo si el usuario aún no marcó hoy
  · Al marcar: cambia a "✓ Asistencia registrada" deshabilitado verde

### Mini calendario semanal
- Lun–Dom con número del día
- Punto debajo de cada día:
  · Verde #22C55E = todos presentes
  · Amarillo #F59E0B = asistencia parcial
  · Rojo #EF4444 = hubo ausencias
  · Sin punto = sin reunión ese día
- Día de hoy: fondo #FF4500 círculo
- Botón "Ver mes" derecha

### Historial
- Título "Historial" + botón "Ver todo"
- Últimas 3 reuniones con: fecha, tipo, % asistencia

---

## Lógica de negocio

### Marcar asistencia
```dart
// Insertar en tabla asistencia
// Manejar UNIQUE constraint: si ya existe mostrar "Ya marcaste hoy"
await supabase.from('asistencia').insert({
  'user_id': userId,
  'fecha': DateTime.now().toIso8601String().split('T')[0],
  'presente': true,
  'hora_entrada': DateTime.now().toIso8601String(),
  'reunion_tipo': 'diaria',
});
```

### Permisos por rol
- CEO / Manager: ven todos los miembros, pueden marcar por cualquiera
- RRHH: ven todos, pueden marcar por cualquiera
- Diseñadora / Producción: solo ven y marcan su propia asistencia

### Cálculo % asistencia mensual
```sql
SELECT COUNT(*) FILTER (WHERE presente = true) * 100.0 / COUNT(*) as porcentaje
FROM asistencia
WHERE user_id = $userId AND fecha >= date_trunc('month', now())
```

---

## Estados a manejar
- Loading: spinner mientras carga la reunión del día
- Sin reunión hoy: EmptyState "No hay reunión programada hoy"
- Ya marcó: botón deshabilitado con check verde
- Error al marcar: mensaje en rojo debajo del botón
- Unique constraint error: "Ya registraste tu asistencia hoy"
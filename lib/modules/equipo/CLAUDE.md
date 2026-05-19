# Módulo: Equipo
> Referencia visual: leer mockups/Equipo.html

---

## Archivos a crear
```
lib/modules/equipo/
├── models/
│   ├── usuario.dart
│   └── bono.dart
├── providers/
│   └── equipo_provider.dart
├── screens/
│   ├── equipo_screen.dart
│   └── perfil_miembro_screen.dart
└── widgets/
    ├── miembro_card.dart
    ├── rol_badge.dart
    ├── asistencia_bar.dart
    └── bonos_card.dart
```

---

## Modelos
```dart
class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? avatarUrl;
  final String? horario;
  final String tema;
  final bool activo;
}

class Bono {
  final String id;
  final String userId;
  final double monto;
  final String motivo;
  final String periodo;
  final String aprobadoPor;
}
```

---

## Pantalla principal (replicar mockups/Equipo.html)

### Header
- Título "Equipo"
- Indicador: "● {n} miembros · {online} online ahora" en #888888
- Botón "+" arriba derecha (solo CEO/RRHH)
- Botón "Ordenar" derecha

### MiembroCard (#141414)
- Avatar circular izquierda con iniciales, fondo por rol:
  · CEO: #F59E0B (dorado)
  · Diseñadora: #A78BFA (púrpura)
  · RRHH: #3B82F6 (azul)
  · Producción: #22C55E (verde)
  · Manager: #F97316 (naranja)
- Punto online: verde #22C55E si activo últimos 5 min, gris si no
- Badge "TÚ" naranja en el miembro logueado
- Nombre en blanco bold
- RolBadge con color del rol
- Horario en #888888 — SIEMPRE formato "HH:MM – HH:MM"
  · Camila (diseñadora): SIEMPRE "12:00 – 18:00" ← NUNCA otro valor
- Tres puntos "···" derecha para opciones
- Barra AsistenciaBar al fondo de la card:
  · Label "ASISTENCIA · MAYO"
  · Porcentaje % derecha con color (>90% verde, 70-90% amarillo, <70% rojo)
  · Barra de progreso con color correspondiente

### BonusCard
- Card completa SIEMPRE visible, NUNCA cortada
- Fondo degradado sutil dorado/oscuro
- Título "Bonos este trimestre"
- Período: "Q{n} · {año}"
- Ícono moneda derecha
- Lista de bonos pendientes (solo CEO/RRHH los ve completos)

---

## Cálculo % asistencia mensual
```sql
SELECT 
  COUNT(*) FILTER (WHERE presente = true) * 100.0 / 
  NULLIF(COUNT(*), 0) as porcentaje
FROM asistencia
WHERE user_id = $userId 
  AND fecha >= date_trunc('month', now())
```

---

## Presence online (Supabase Realtime)
```dart
// Usar Supabase Realtime Presence para indicador online
final channel = supabase.channel('online-users');
channel.subscribe((status) {
  if (status == 'SUBSCRIBED') {
    channel.track({'user_id': currentUserId, 'online_at': DateTime.now()});
  }
});
```

---

## Permisos por rol
- CEO: CRUD completo, ve bonos de todos
- RRHH: CRUD de perfiles, gestiona bonos
- Manager: solo lectura
- Diseñadora / Producción: sin acceso al módulo

---

## REGLA CRÍTICA
El horario de Camila (diseñadora) es SIEMPRE "12:00 – 18:00".
Validar que campo horario tenga formato correcto HH:MM–HH:MM antes de guardar.
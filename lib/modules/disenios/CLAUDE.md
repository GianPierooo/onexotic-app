# Módulo: Diseños
> Referencia visual: leer mockups/Disenios.html y mockups/Brief.html

---

## Archivos a crear
```
lib/modules/disenios/
├── models/
│   ├── disenio.dart
│   └── brief.dart
├── providers/
│   ├── disenios_provider.dart
│   └── briefs_provider.dart
├── screens/
│   ├── disenios_screen.dart
│   ├── brief_screen.dart
│   └── aprobacion_screen.dart
└── widgets/
    ├── disenio_card.dart
    ├── estado_chip.dart
    ├── brief_form.dart
    ├── color_chip.dart
    └── referencia_imagen_grid.dart
```

---

## Modelos
```dart
class Disenio {
  final String id;
  final String titulo;
  final String? dropId;
  final String diseñadoraId;
  final String estado; // brief|proceso|revision|aprobado|rechazado
  final String? archivoUrl;
  final String? thumbnailUrl;
  final String? aprobadoPor;
  final DateTime? fechaLimite;
  final String? feedback;
  final int version;
}

class Brief {
  final String id;
  final String disenioId;
  final String titulo;
  final String? descripcion;
  final List<String> referenciasUrls;
  final List<String> colores;
  final String? tipografia;
  final String? notasAdicionales;
  final DateTime? fechaLimite;
}
```

---

## Pantalla principal (replicar mockups/Disenios.html)

### Header
- Título "Diseños"
- Alerta naranja si hay diseños en revisión: "X esperan tu aprobación" (solo CEO)
- Tabs scrolleables: Todos · Brief · En proceso · Revisión · Aprobados · Rechazados
- Tab activo: línea inferior #FF4500

### DisenioCard (#141414)
- Thumbnail cuadrado izquierda con badge de versión "v3" arriba izquierda
- Título en blanco
- Drop asociado + nombre diseñadora en #888888
- EstadoChip con color correspondiente
- Fecha límite en #888888
- Si estado = 'revision' y rol = CEO: botones "Rechazar" y "Aprobar" visibles

### Colores de estado
```dart
'brief':     Color(0xFF3B82F6)  // azul
'proceso':   Color(0xFFF59E0B)  // amarillo
'revision':  Color(0xFFFF4500)  // naranja
'aprobado':  Color(0xFF22C55E)  // verde
'rechazado': Color(0xFFEF4444)  // rojo
```

---

## Flujo de aprobación
1. CEO ve diseño en 'revision'
2. Toca "Aprobar" → estado='aprobado', aprobado_por=userId, updated_at=now()
3. Toca "Rechazar" → abre modal con campo feedback OBLIGATORIO
4. Al rechazar: estado='rechazado', feedback=texto
5. Notificación automática a diseñadora en ambos casos
6. Al reenviar diseño rechazado: version += 1

---

## Pantalla Brief (replicar mockups/Brief.html)

### Header
- Flecha atrás
- Título "Nuevo Brief"
- Estado "BORRADOR · GUARDADO" en #888888
- Botón "Enviar →" #FF4500

### Campos del formulario
Todos sobre fondo #1E1E1E, label arriba en #888888, borde #2A2A2A, focus #FF4500:

1. TÍTULO DEL DISEÑO* — input texto
2. DROP ASOCIADO* — selector pills (EXOTIC0 · Ñ · Drop 003)
   - Pill seleccionado: fondo #FF4500, texto blanco, borde #FF4500
3. DESCRIPCIÓN* — textarea, contador caracteres "168/500"
4. COLORES DE REFERENCIA — chips de color agregables con "+" botón
   - Cada chip: círculo de color + código hex + X para quitar
5. REFERENCIAS VISUALES — grid de imágenes subibles "2/8"
   - Thumbnails cuadrados con X para quitar + botón "SUBIR"
6. TIPOGRAFÍA SUGERIDA — input texto
7. FECHA LÍMITE* — date picker
8. NOTAS ADICIONALES — textarea

### Validación
- Campos con * son obligatorios
- Mostrar error inline debajo del campo
- Botón Enviar deshabilitado hasta que campos obligatorios estén completos

---

## Storage Supabase
- Bucket: 'disenos'
- Path thumbnails: {drop_id}/{disenio_id}/thumb_v{version}.jpg
- Path archivos: {drop_id}/{disenio_id}/v{version}.{ext}

---

## Permisos por rol
- CEO: CRUD completo, aprobar/rechazar
- Diseñadora: solo sus propios diseños, cambiar estado de brief→proceso→revision
- Producción: solo ver aprobados
- RRHH: sin acceso
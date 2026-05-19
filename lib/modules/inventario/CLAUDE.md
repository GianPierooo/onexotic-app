# Módulo: Inventario
> Referencia visual: leer mockups/Inventario.html

---

## Archivos a crear
```
lib/modules/inventario/
├── models/
│   ├── producto.dart
│   └── drop.dart
├── providers/
│   ├── inventario_provider.dart
│   └── drops_provider.dart
├── screens/
│   ├── inventario_screen.dart
│   └── producto_detail_screen.dart
└── widgets/
    ├── producto_card.dart
    ├── talla_chip.dart
    ├── stock_badge.dart
    ├── alerta_stock_banner.dart
    └── drop_filter_pills.dart
```

---

## Modelos
```dart
class Producto {
  final String id;
  final String nombre;
  final String tipo; // polo|short|pantalon|polera|accesorio
  final String? dropId;
  final String talla; // XS|S|M|L|XL|XXL
  final String? color;
  final int stock;
  final int stockMinimo;
  final double? costo;
  final double? precioVenta;
  final String estado; // activo|agotado|descontinuado
  final String? imagenUrl;
  final String? sku;
}
```

---

## Pantalla principal (replicar mockups/Inventario.html)

### Header
- Título "Inventario"
- Badge total: "47 SKUs" en #888888
- Barra de búsqueda: busca por nombre, SKU o drop
- Ícono filtro derecha con badge si hay filtros activos

### Drop filter pills (scroll horizontal)
- Todos · EXOTIC0 · Ñ · Drop 003 · ...
- Cargar drops dinámicamente desde tabla drops
- Pill activo: #FF4500, pill inactivo: #1E1E1E

### AlertaStockBanner
- Visible SOLO si hay productos con stock <= stock_minimo
- Fondo #EF4444/15, borde izquierdo 3px #EF4444
- Ícono alerta triángulo
- Texto: "{n} productos con stock bajo · Reordenar antes del próximo drop"
- Flecha → al tocar filtra solo críticos

### ProductoCard (#141414)
- Thumbnail cuadrado izquierda (placeholder con ícono imagen si no hay foto)
- Nombre en blanco bold
- Tipo + drop en #888888
- SKU en #555555 pequeño
- Fila de TallaChips — scroll horizontal (NUNCA cortados)
- Stock número derecha con StockBadge

### TallaChip
```dart
// Con stock: fondo #1E1E1E, texto blanco, borde #2A2A2A
// Sin stock: texto tachado, color #555555, borde #1E1E1E
// Tallas: XS · S · M · L · XL · XXL
// IMPORTANTE: siempre en scroll horizontal, nunca cortadas
```

### StockBadge colores
```dart
// stock > 10:  #22C55E (verde)  → "EN STOCK"
// stock 5-10:  #F59E0B (amarillo)
// stock 1-4:   #EF4444 (rojo)
// stock = 0:   #555555 (gris)   → "AGOTADO"
```

---

## Pantalla detalle de producto
- Imagen grande arriba
- Nombre, tipo, drop, SKU
- Grid de tallas con stock individual por talla
- Costo y precio de venta (solo CEO/Manager/Producción)
- Historial de movimientos de stock
- Botón "Editar stock" para ajustar manualmente

---

## Ordenamiento default
- Por stock ASC (críticos primero)
- Opciones: por nombre, por drop, por tipo

---

## Permisos por rol
- CEO / Manager / Producción: CRUD completo, ven costos y precios
- Diseñadora / RRHH: SIN ACCESO a este módulo en absoluto

---

## SKU format
```
{TIPO-ABREV}-{DROP-ABREV}-{NRO}
Ejemplo: EX-HD-001 (EXOTIC0, Hoodie, 001)
         N-PL-007  (Ñ, Polera, 007)
         D3-PT-012 (Drop 003, Pantalón, 012)
```
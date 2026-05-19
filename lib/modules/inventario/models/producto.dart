class Producto {
  final String id;
  final String nombre;
  final String tipo; // polo|short|pantalon|polera|accesorio
  final String? dropId;
  final String? dropNombre;
  final String talla; // XS|S|M|L|XL|XXL
  final String? color;
  final int stock;
  final int stockMinimo;
  final double? costo;
  final double? precioVenta;
  final String estado; // activo|agotado|descontinuado
  final String? imagenUrl;
  final String? sku;
  final DateTime createdAt;

  const Producto({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.dropId,
    this.dropNombre,
    required this.talla,
    this.color,
    required this.stock,
    required this.stockMinimo,
    this.costo,
    this.precioVenta,
    required this.estado,
    this.imagenUrl,
    this.sku,
    required this.createdAt,
  });

  bool get esCritico => stock <= stockMinimo && stock > 0;
  bool get esAgotado => stock == 0;

  factory Producto.fromJson(Map<String, dynamic> json) {
    final dropsData = json['drops'] as Map<String, dynamic>?;
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'polo',
      dropId: json['drop_id'] as String?,
      dropNombre: dropsData?['nombre'] as String?,
      talla: json['talla'] as String? ?? 'M',
      color: json['color'] as String?,
      stock: json['stock'] as int? ?? 0,
      stockMinimo: json['stock_minimo'] as int? ?? 5,
      costo: (json['costo'] as num?)?.toDouble(),
      precioVenta: (json['precio_venta'] as num?)?.toDouble(),
      estado: json['estado'] as String? ?? 'activo',
      imagenUrl: json['imagen_url'] as String?,
      sku: json['sku'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static String labelTipo(String tipo) => switch (tipo) {
        'polo'      => 'Polo',
        'short'     => 'Short',
        'pantalon'  => 'Pantalón',
        'polera'    => 'Polera',
        'accesorio' => 'Accesorio',
        _           => tipo,
      };
}

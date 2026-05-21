class Proveedor {
  final String id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? tipo;
  final int? rating;
  final String? notas;
  final bool activo;
  final DateTime createdAt;
  final int productosAsociados;

  const Proveedor({
    required this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.tipo,
    this.rating,
    this.notas,
    required this.activo,
    required this.createdAt,
    this.productosAsociados = 0,
  });

  static const tiposDisponibles = <(String, String)>[
    ('tela', 'Tela'),
    ('estampado', 'Estampado'),
    ('confeccion', 'Confección'),
    ('packaging', 'Packaging'),
  ];

  String get tipoLabel => switch (tipo) {
        'tela' => 'Tela',
        'estampado' => 'Estampado',
        'confeccion' => 'Confección',
        'packaging' => 'Packaging',
        _ => 'Sin tipo',
      };

  factory Proveedor.fromJson(Map<String, dynamic> j, {int productos = 0}) {
    return Proveedor(
      id: j['id'] as String,
      nombre: j['nombre'] as String? ?? '',
      contacto: j['contacto'] as String?,
      telefono: j['telefono'] as String?,
      tipo: j['tipo'] as String?,
      rating: (j['rating'] as num?)?.toInt(),
      notas: j['notas'] as String?,
      activo: j['activo'] as bool? ?? true,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
          DateTime.now(),
      productosAsociados: productos,
    );
  }
}

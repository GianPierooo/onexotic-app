class Drop {
  final String id;
  final String nombre;
  final String? estado;
  final String? concepto;
  final DateTime? fechaLanzamiento;

  const Drop({
    required this.id,
    required this.nombre,
    this.estado,
    this.concepto,
    this.fechaLanzamiento,
  });

  factory Drop.fromJson(Map<String, dynamic> json) => Drop(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        estado: json['estado'] as String?,
        concepto: json['concepto'] as String?,
        fechaLanzamiento: json['fecha_lanzamiento'] != null
            ? DateTime.tryParse(json['fecha_lanzamiento'] as String)
            : null,
      );
}

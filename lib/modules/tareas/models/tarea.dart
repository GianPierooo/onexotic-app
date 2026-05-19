class Tarea {
  final String id;
  final String titulo;
  final String? descripcion;
  final String area;
  final String prioridad;
  final String? asignadoA;
  final bool completado;
  final DateTime? fechaLimite;
  final String? imagenUrl;
  final DateTime createdAt;

  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.area,
    required this.prioridad,
    this.asignadoA,
    required this.completado,
    this.fechaLimite,
    this.imagenUrl,
    required this.createdAt,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      area: json['area'] as String,
      prioridad: json['prioridad'] as String,
      asignadoA: json['asignado_a'] as String?,
      completado: json['completado'] as bool? ?? false,
      fechaLimite: json['fecha_limite'] != null
          ? DateTime.tryParse(json['fecha_limite'] as String)
          : null,
      imagenUrl: json['imagen_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Tarea copyWith({bool? completado}) {
    return Tarea(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      area: area,
      prioridad: prioridad,
      asignadoA: asignadoA,
      completado: completado ?? this.completado,
      fechaLimite: fechaLimite,
      imagenUrl: imagenUrl,
      createdAt: createdAt,
    );
  }
}

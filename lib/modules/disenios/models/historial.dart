class DisenioHistorial {
  final String id;
  final String disenioId;
  final String accion;
  final String? descripcion;
  final String? usuarioId;
  final String? usuarioNombre;
  final DateTime createdAt;

  const DisenioHistorial({
    required this.id,
    required this.disenioId,
    required this.accion,
    this.descripcion,
    this.usuarioId,
    this.usuarioNombre,
    required this.createdAt,
  });

  factory DisenioHistorial.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    return DisenioHistorial(
      id: json['id'] as String,
      disenioId: json['disenio_id'] as String,
      accion: json['accion'] as String,
      descripcion: json['descripcion'] as String?,
      usuarioId: json['usuario_id'] as String?,
      usuarioNombre: userData?['nombre'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

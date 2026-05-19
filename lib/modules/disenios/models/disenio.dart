class Disenio {
  final String id;
  final String titulo;
  final String? dropId;
  final String? dropNombre;
  final String disenadoraId;
  final String estado; // brief|proceso|revision|aprobado|rechazado
  final String? thumbnailUrl;
  final String? aprobadoPor;
  final DateTime? fechaLimite;
  final String? feedback;
  final int version;
  final DateTime createdAt;

  const Disenio({
    required this.id,
    required this.titulo,
    this.dropId,
    this.dropNombre,
    required this.disenadoraId,
    required this.estado,
    this.thumbnailUrl,
    this.aprobadoPor,
    this.fechaLimite,
    this.feedback,
    required this.version,
    required this.createdAt,
  });

  factory Disenio.fromJson(Map<String, dynamic> json) {
    final dropsData = json['drops'] as Map<String, dynamic>?;
    return Disenio(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      dropId: json['drop_id'] as String?,
      dropNombre: dropsData?['nombre'] as String?,
      disenadoraId: json['disenadora_id'] as String,
      estado: json['estado'] as String? ?? 'brief',
      thumbnailUrl: json['thumbnail_url'] as String?,
      aprobadoPor: json['aprobado_por'] as String?,
      fechaLimite: json['fecha_limite'] != null
          ? DateTime.tryParse(json['fecha_limite'] as String)
          : null,
      feedback: json['feedback'] as String?,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Disenio copyWith({
    String? estado,
    String? feedback,
    String? aprobadoPor,
  }) =>
      Disenio(
        id: id,
        titulo: titulo,
        dropId: dropId,
        dropNombre: dropNombre,
        disenadoraId: disenadoraId,
        estado: estado ?? this.estado,
        thumbnailUrl: thumbnailUrl,
        aprobadoPor: aprobadoPor ?? this.aprobadoPor,
        fechaLimite: fechaLimite,
        feedback: feedback ?? this.feedback,
        version: version,
        createdAt: createdAt,
      );
}

class DisenioAvance {
  final String id;
  final String disenioId;
  final String imagenUrl;
  final String? nota;
  final String? subidoPor;
  final DateTime createdAt;

  const DisenioAvance({
    required this.id,
    required this.disenioId,
    required this.imagenUrl,
    this.nota,
    this.subidoPor,
    required this.createdAt,
  });

  factory DisenioAvance.fromJson(Map<String, dynamic> json) => DisenioAvance(
        id: json['id'] as String,
        disenioId: json['disenio_id'] as String,
        imagenUrl: json['imagen_url'] as String,
        nota: json['nota'] as String?,
        subidoPor: json['subido_por'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

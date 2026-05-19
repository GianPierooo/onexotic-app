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
  final String? creadoPor;
  final DateTime createdAt;

  const Brief({
    required this.id,
    required this.disenioId,
    required this.titulo,
    this.descripcion,
    required this.referenciasUrls,
    required this.colores,
    this.tipografia,
    this.notasAdicionales,
    this.fechaLimite,
    this.creadoPor,
    required this.createdAt,
  });

  factory Brief.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return Brief(
      id: json['id'] as String,
      disenioId: json['disenio_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      referenciasUrls: _parseStringList(json['referencias_urls']),
      colores: _parseStringList(json['colores']),
      tipografia: json['tipografia'] as String?,
      notasAdicionales: json['notas_adicionales'] as String?,
      fechaLimite: json['fecha_limite'] != null
          ? DateTime.tryParse(json['fecha_limite'] as String)
          : null,
      creadoPor: json['creado_por'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

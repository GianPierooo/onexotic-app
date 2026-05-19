class Bono {
  final String id;
  final String userId;
  final double monto;
  final String motivo;
  final String periodo;
  final String? aprobadoPor;
  final DateTime createdAt;

  const Bono({
    required this.id,
    required this.userId,
    required this.monto,
    required this.motivo,
    required this.periodo,
    this.aprobadoPor,
    required this.createdAt,
  });

  factory Bono.fromJson(Map<String, dynamic> json) => Bono(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        monto: (json['monto'] as num).toDouble(),
        motivo: json['motivo'] as String? ?? '',
        periodo: json['periodo'] as String? ?? '',
        aprobadoPor: json['aprobado_por'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

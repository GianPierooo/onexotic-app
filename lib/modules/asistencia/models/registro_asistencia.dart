class RegistroAsistencia {
  final String id;
  final String userId;
  final DateTime fecha;
  final bool presente;
  final DateTime? horaEntrada;
  final String? nota;
  final String reunionTipo;

  const RegistroAsistencia({
    required this.id,
    required this.userId,
    required this.fecha,
    required this.presente,
    this.horaEntrada,
    this.nota,
    required this.reunionTipo,
  });

  factory RegistroAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistroAsistencia(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      presente: json['presente'] as bool,
      horaEntrada: json['hora_entrada'] != null
          ? DateTime.parse(json['hora_entrada'] as String)
          : null,
      nota: json['nota'] as String?,
      reunionTipo: json['reunion_tipo'] as String,
    );
  }
}

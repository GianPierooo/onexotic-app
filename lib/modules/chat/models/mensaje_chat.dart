class MensajeChat {
  final String id;
  final String deUserId;
  final String paraUserId;
  final String mensaje;
  final bool leido;
  final DateTime createdAt;

  const MensajeChat({
    required this.id,
    required this.deUserId,
    required this.paraUserId,
    required this.mensaje,
    required this.leido,
    required this.createdAt,
  });

  bool esPropio(String currentUserId) => deUserId == currentUserId;

  factory MensajeChat.fromJson(Map<String, dynamic> j) => MensajeChat(
        id: j['id'] as String,
        deUserId: j['de_user_id'] as String,
        paraUserId: j['para_user_id'] as String,
        mensaje: j['mensaje'] as String,
        leido: j['leido'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '') ??
                DateTime.now(),
      );

  MensajeChat copyWith({bool? leido}) => MensajeChat(
        id: id,
        deUserId: deUserId,
        paraUserId: paraUserId,
        mensaje: mensaje,
        leido: leido ?? this.leido,
        createdAt: createdAt,
      );
}

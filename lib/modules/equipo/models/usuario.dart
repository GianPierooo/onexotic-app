class Usuario {
  final String id;
  final String nombre;
  final String? apellido;
  final String email;
  final String rol;
  final String? avatarUrl;
  final String? horario;
  final String? telefono;
  final String tema;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.email,
    required this.rol,
    this.avatarUrl,
    this.horario,
    this.telefono,
    required this.tema,
    required this.activo,
  });

  String get nombreCompleto {
    if (apellido != null && apellido!.isNotEmpty) return '$nombre $apellido';
    return nombre;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        apellido: json['apellido'] as String?,
        email: json['email'] as String,
        rol: json['rol'] as String? ?? 'manager',
        avatarUrl: json['avatar_url'] as String?,
        horario: json['horario'] as String?,
        telefono: json['telefono'] as String?,
        tema: json['tema'] as String? ?? 'dark',
        activo: json['activo'] as bool? ?? true,
      );

  // Camila (disenadora) SIEMPRE 12:00 – 18:00
  String get horarioDisplay {
    if (rol == 'disenadora') return '12:00 – 18:00';
    final h = horario;
    if (h == null || h.isEmpty) return '--:-- – --:--';
    // Normaliza separador a " – "
    return h.replaceAll('-', ' – ').replaceAll('–', ' – ').replaceAll('  ', ' ');
  }

  static String labelRol(String rol) => switch (rol) {
        'ceo'        => 'CEO',
        'manager'    => 'Manager',
        'disenadora' => 'Diseñadora',
        'rrhh'       => 'RRHH',
        'produccion' => 'Producción',
        _            => rol.toUpperCase(),
      };
}

enum Rol {
  ceo,
  manager,
  disenadora,
  rrhh,
  produccion;

  static Rol fromString(String value) {
    return Rol.values.firstWhere(
      (r) => r.name == value,
      orElse: () => Rol.ceo,
    );
  }

  bool get puedeVerCostos => this == ceo || this == manager;
  bool get puedeGestionarEquipo => this == ceo || this == rrhh;
  bool get puedeAprobarDisenios => this == ceo;
  bool get puedeVerInventario => this == ceo || this == manager || this == produccion;
  bool get puedeCrearTareas => this == ceo || this == manager;
  bool get puedeGestionarAsistencia => this == ceo || this == rrhh;
}

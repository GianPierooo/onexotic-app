class AiContextBuilder {
  AiContextBuilder._();

  static List<String> sugerenciasPorRol(String rol) {
    switch (rol) {
      case 'ceo':
      case 'manager':
        return ['Resumen del día', 'Stock crítico', 'Ventas semana'];
      case 'disenadora':
        return ['Mis diseños activos', 'Ideas de paleta', 'Próxima entrega', 'Tendencias actuales'];
      case 'rrhh':
        return ['Asistencia hoy', 'Quién faltó', 'Bonos pendientes'];
      case 'produccion':
        return ['Stock actual', 'Próximo drop', 'Proveedores'];
      default:
        return ['Resumen del día', 'Mis tareas', 'Próxima reunión'];
    }
  }
}

// Tipos de base de datos generados desde el schema de Supabase.
// Tablas: users, drops, productos, asistencia, disenios, briefs,
//         tareas, notificaciones, bonos, proveedores

// ignore_for_file: constant_identifier_names

class DbTable {
  static const String users = 'users';
  static const String drops = 'drops';
  static const String productos = 'productos';
  static const String asistencia = 'asistencia';
  static const String disenios = 'disenios';
  static const String briefs = 'briefs';
  static const String tareas = 'tareas';
  static const String notificaciones = 'notificaciones';
  static const String bonos = 'bonos';
  static const String proveedores = 'proveedores';
}

// ─── users ────────────────────────────────────────────────────────────────────

class DbUser {
  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String email = 'email';
  static const String rol = 'rol';
  static const String avatarUrl = 'avatar_url';
  static const String horario = 'horario';
  static const String tema = 'tema';
  static const String activo = 'activo';
  static const String createdAt = 'created_at';
}

class RolValue {
  static const String ceo = 'ceo';
  static const String manager = 'manager';
  static const String disenadora = 'disenadora';
  static const String rrhh = 'rrhh';
  static const String produccion = 'produccion';
}

class TemaValue {
  static const String dark = 'dark';
  static const String light = 'light';
}

// ─── drops ────────────────────────────────────────────────────────────────────

class DbDrop {
  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String concepto = 'concepto';
  static const String fechaLanzamiento = 'fecha_lanzamiento';
  static const String estado = 'estado';
  static const String createdAt = 'created_at';
}

class DropEstado {
  static const String planificacion = 'planificacion';
  static const String produccion = 'produccion';
  static const String lanzado = 'lanzado';
  static const String agotado = 'agotado';
}

// ─── productos ────────────────────────────────────────────────────────────────

class DbProducto {
  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String tipo = 'tipo';
  static const String dropId = 'drop_id';
  static const String talla = 'talla';
  static const String color = 'color';
  static const String stock = 'stock';
  static const String stockMinimo = 'stock_minimo';
  static const String costo = 'costo';
  static const String precioVenta = 'precio_venta';
  static const String estado = 'estado';
  static const String imagenUrl = 'imagen_url';
  static const String sku = 'sku';
  static const String createdAt = 'created_at';
}

class ProductoTipo {
  static const String polo = 'polo';
  static const String short = 'short';
  static const String pantalon = 'pantalon';
  static const String polera = 'polera';
  static const String accesorio = 'accesorio';
}

class ProductoTalla {
  static const String xs = 'XS';
  static const String s = 'S';
  static const String m = 'M';
  static const String l = 'L';
  static const String xl = 'XL';
  static const String xxl = 'XXL';

  static const List<String> all = [xs, s, m, l, xl, xxl];
}

class ProductoEstado {
  static const String activo = 'activo';
  static const String agotado = 'agotado';
  static const String descontinuado = 'descontinuado';
}

// ─── asistencia ───────────────────────────────────────────────────────────────

class DbAsistencia {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String fecha = 'fecha';
  static const String presente = 'presente';
  static const String horaEntrada = 'hora_entrada';
  static const String nota = 'nota';
  static const String reunionTipo = 'reunion_tipo';
  static const String createdAt = 'created_at';
}

class ReunionTipo {
  static const String diaria = 'diaria';
  static const String semanal = 'semanal';
  static const String extraordinaria = 'extraordinaria';
}

// ─── disenios ─────────────────────────────────────────────────────────────────

class DbDisenio {
  static const String id = 'id';
  static const String titulo = 'titulo';
  static const String dropId = 'drop_id';
  static const String disenadoId = 'disenadora_id';
  static const String estado = 'estado';
  static const String archivoUrl = 'archivo_url';
  static const String thumbnailUrl = 'thumbnail_url';
  static const String aprobadoPor = 'aprobado_por';
  static const String fechaLimite = 'fecha_limite';
  static const String feedback = 'feedback';
  static const String version = 'version';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class DisenioEstado {
  static const String brief = 'brief';
  static const String proceso = 'proceso';
  static const String revision = 'revision';
  static const String aprobado = 'aprobado';
  static const String rechazado = 'rechazado';
}

// ─── briefs ───────────────────────────────────────────────────────────────────

class DbBrief {
  static const String id = 'id';
  static const String disenioId = 'disenio_id';
  static const String titulo = 'titulo';
  static const String descripcion = 'descripcion';
  static const String referenciasUrls = 'referencias_urls';
  static const String colores = 'colores';
  static const String tipografia = 'tipografia';
  static const String notasAdicionales = 'notas_adicionales';
  static const String fechaLimite = 'fecha_limite';
  static const String creadoPor = 'creado_por';
  static const String createdAt = 'created_at';
}

// ─── tareas ───────────────────────────────────────────────────────────────────

class DbTarea {
  static const String id = 'id';
  static const String titulo = 'titulo';
  static const String descripcion = 'descripcion';
  static const String area = 'area';
  static const String prioridad = 'prioridad';
  static const String asignadoA = 'asignado_a';
  static const String completado = 'completado';
  static const String fechaLimite = 'fecha_limite';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class TareaArea {
  static const String tech = 'tech';
  static const String disenio = 'disenio';
  static const String marketing = 'marketing';
  static const String produccion = 'produccion';
  static const String rrhh = 'rrhh';
  static const String legal = 'legal';
}

class TareaPrioridad {
  static const String alta = 'alta';
  static const String media = 'media';
  static const String baja = 'baja';
}

// ─── notificaciones ───────────────────────────────────────────────────────────

class DbNotificacion {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String titulo = 'titulo';
  static const String mensaje = 'mensaje';
  static const String tipo = 'tipo';
  static const String leido = 'leido';
  static const String createdAt = 'created_at';
}

class NotificacionTipo {
  static const String asistencia = 'asistencia';
  static const String disenio = 'disenio';
  static const String tarea = 'tarea';
  static const String inventario = 'inventario';
  static const String bono = 'bono';
  static const String sistema = 'sistema';
}

// ─── bonos ────────────────────────────────────────────────────────────────────

class DbBono {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String monto = 'monto';
  static const String motivo = 'motivo';
  static const String periodo = 'periodo';
  static const String aprobadoPor = 'aprobado_por';
  static const String createdAt = 'created_at';
}

// ─── proveedores ──────────────────────────────────────────────────────────────

class DbProveedor {
  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String contacto = 'contacto';
  static const String telefono = 'telefono';
  static const String tipo = 'tipo';
  static const String rating = 'rating';
  static const String notas = 'notas';
  static const String activo = 'activo';
  static const String createdAt = 'created_at';
}

class ProveedorTipo {
  static const String tela = 'tela';
  static const String estampado = 'estampado';
  static const String confeccion = 'confeccion';
  static const String packaging = 'packaging';
}

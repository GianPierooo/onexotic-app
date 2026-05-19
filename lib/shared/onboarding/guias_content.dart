import 'guia_slide.dart';

abstract class GuiasContent {
  // ── Dashboard ──────────────────────────────────────────────────────────────
  static const dashboard = [
    GuiaSlide(
      emoji: '🏠',
      titulo: 'Bienvenido a OnExotic',
      texto:
          'Este es tu centro de control. Desde aquí puedes ver el estado de tu negocio de un vistazo.',
    ),
    GuiaSlide(
      emoji: '📊',
      titulo: 'Métricas en tiempo real',
      texto:
          'Las 4 cards muestran: stock crítico, tareas pendientes, asistencia de hoy y días para el próximo drop. Todo actualizado automáticamente.',
    ),
    GuiaSlide(
      emoji: '🗺️',
      titulo: 'Flujo de trabajo diario',
      texto:
          'Tu día en OnExotic sigue este orden:\n1. Marca tu asistencia a la reunión diaria\n2. Revisa y actualiza tus tareas del día\n3. Si eres CEO, revisa los diseños pendientes\n4. Actualiza el inventario si hay movimientos\n5. Usa el Asistente IA para consultas rápidas',
    ),
    GuiaSlide(
      emoji: '✅',
      titulo: '¡Listo para empezar!',
      texto:
          'Empieza marcando tu asistencia de hoy.\nToca el ícono de Asistencia en el menú inferior.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── Asistencia ─────────────────────────────────────────────────────────────
  static const asistencia = [
    GuiaSlide(
      emoji: '📋',
      titulo: 'Control de asistencia',
      texto:
          'Aquí registras la asistencia a las reuniones diarias del equipo OnExotic. Las reuniones son todos los días a las 9:00 AM en el Showroom.',
    ),
    GuiaSlide(
      emoji: '✅',
      titulo: 'Cómo marcar tu asistencia',
      texto:
          'Al llegar a la reunión, abre esta pantalla y toca "Marcar mi asistencia". Solo puedes hacerlo una vez por reunión. Si no marcas, quedas como Pendiente.',
    ),
    GuiaSlide(
      emoji: '👑',
      titulo: 'Si eres CEO',
      texto:
          'Como CEO puedes:\n- Crear nuevas reuniones con el botón +\n- Ver el estado de todo el equipo\n- Marcar la asistencia de cualquier miembro\n- Ver el historial mensual de asistencia',
    ),
    GuiaSlide(
      emoji: '📅',
      titulo: 'Después de la asistencia',
      texto:
          'Una vez marcada tu asistencia, ve a Tareas para revisar y actualizar las pendientes del día.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── Tareas ─────────────────────────────────────────────────────────────────
  static const tareas = [
    GuiaSlide(
      emoji: '✅',
      titulo: 'Gestión de tareas',
      texto:
          'Aquí viven todas las tareas del equipo OnExotic organizadas por área y prioridad.',
    ),
    GuiaSlide(
      emoji: '🎯',
      titulo: 'Prioridades',
      texto:
          'Cada tarea tiene una prioridad:\n🔴 Alta → hacer hoy sin falta\n🟡 Media → esta semana\n🟢 Baja → cuando haya tiempo\n\nFiltra por área: Tech, Diseño, Marketing, Producción, RRHH, Legal.',
    ),
    GuiaSlide(
      emoji: '➕',
      titulo: 'Crear tareas (solo CEOs)',
      texto:
          'Como CEO puedes crear y asignar tareas a cualquier miembro del equipo. Toca el botón + para crear una nueva.',
    ),
    GuiaSlide(
      emoji: '🔄',
      titulo: 'Después de las tareas',
      texto:
          'Si hay diseños pendientes de revisar, ve a Diseños. Si hay stock bajo en inventario, actualízalo. Mantén las tareas al día para que el equipo funcione bien.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── Diseños ────────────────────────────────────────────────────────────────
  static const disenios = [
    GuiaSlide(
      emoji: '🎨',
      titulo: 'Flujo de diseños',
      texto:
          'Aquí gestionas todo el proceso creativo de OnExotic, desde la idea hasta el producto final.',
    ),
    GuiaSlide(
      emoji: '📝',
      titulo: 'Paso 1: El Brief',
      texto:
          'Todo empieza con un Brief. El CEO crea un brief con: título, drop asociado, descripción, colores de referencia, imágenes e inspiración, tipografía y fecha límite de entrega.',
    ),
    GuiaSlide(
      emoji: '🖌️',
      titulo: 'Paso 2: Proceso y avance',
      texto:
          'La diseñadora recibe el brief, inicia el proceso y sube avances para que el CEO pueda monitorear el progreso en tiempo real.',
    ),
    GuiaSlide(
      emoji: '👁️',
      titulo: 'Paso 3: Revisión',
      texto:
          'Cuando la diseñadora termina, envía el diseño a revisión. El CEO puede:\n✅ Aprobar → pasa a producción\n❌ Rechazar → la diseñadora recibe feedback y sube una nueva versión.',
    ),
    GuiaSlide(
      emoji: '👕',
      titulo: 'Paso 4: Producción e inventario',
      texto:
          'Al aprobar un diseño, toca "Crear en inventario" para registrar las prendas con sus tallas y cantidades a producir. El diseño queda vinculado al producto en inventario.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── Inventario ─────────────────────────────────────────────────────────────
  static const inventario = [
    GuiaSlide(
      emoji: '📦',
      titulo: 'Control de inventario',
      texto:
          'Aquí controlas todo el stock de prendas OnExotic, organizado por drops y tallas.',
    ),
    GuiaSlide(
      emoji: '➕',
      titulo: 'Agregar productos',
      texto:
          'Toca + para agregar un producto nuevo. Puedes agregar el stock de todas las tallas de una sola vez. El SKU se genera automáticamente.',
    ),
    GuiaSlide(
      emoji: '🚨',
      titulo: 'Alertas de stock',
      texto:
          'Cuando el stock baja del mínimo configurado, aparece una alerta roja arriba. Tócala para ver qué productos necesitas reordenar antes del próximo drop.',
    ),
    GuiaSlide(
      emoji: '🗂️',
      titulo: 'Organización por drops',
      texto:
          'Filtra por drop para ver solo los productos de EXOTIC0, Ñ, Drop 003, etc. Crea nuevos drops con el botón + Nuevo drop cuando planifiques una nueva colección.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── Equipo ─────────────────────────────────────────────────────────────────
  static const equipo = [
    GuiaSlide(
      emoji: '👥',
      titulo: 'Tu equipo OnExotic',
      texto:
          'Aquí gestionas a todos los miembros del equipo, sus roles, horarios y desempeño.',
    ),
    GuiaSlide(
      emoji: '➕',
      titulo: 'Agregar miembros (solo CEOs)',
      texto:
          'Toca + para invitar a un nuevo miembro. Llena sus datos: nombre, email, rol y horario. El miembro recibirá acceso a la app con los permisos de su rol automáticamente.',
    ),
    GuiaSlide(
      emoji: '📊',
      titulo: 'Seguimiento de asistencia',
      texto:
          'Cada tarjeta muestra el % de asistencia mensual del miembro.\nVerde = excelente\nAmarillo = regular\nRojo = necesita atención',
    ),
    GuiaSlide(
      emoji: '💰',
      titulo: 'Sistema de bonos',
      texto:
          'Gestiona los bonos del equipo por trimestre desde la sección Bonos. Solo CEOs y RRHH pueden crear y aprobar bonos.',
      botonFinal: '¡Entendido!',
    ),
  ];

  // ── IA ─────────────────────────────────────────────────────────────────────
  static const ia = [
    GuiaSlide(
      emoji: '🤖',
      titulo: 'IA OnExotic',
      texto:
          'Tu asistente inteligente con acceso a todos los datos de OnExotic en tiempo real.',
    ),
    GuiaSlide(
      emoji: '💬',
      titulo: 'Qué puedes preguntar',
      texto:
          'Como CEO puedes preguntar:\n- "¿Cuánto stock queda del Drop Ñ?"\n- "¿Qué tareas urgentes hay hoy?"\n- "¿Quién faltó esta semana?"\n- "Resume el estado de los diseños"',
    ),
    GuiaSlide(
      emoji: '🔒',
      titulo: 'Acceso según tu rol',
      texto:
          'Cada rol solo puede consultar su área:\n- Diseñadora → sus diseños y briefs\n- RRHH → asistencia y equipo\n- Producción → stock y proveedores\n- CEO → todo sin límites',
    ),
    GuiaSlide(
      emoji: '⚡',
      titulo: 'Tips para mejores respuestas',
      texto:
          'Sé específico en tus preguntas. Usa las sugerencias rápidas de abajo para consultas frecuentes. Las respuestas son cortas y directas para ahorrar tiempo.',
      botonFinal: '¡Empezar a usar!',
    ),
  ];
}

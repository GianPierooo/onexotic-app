import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Item del sheet "Más" — referencia la ruta absoluta del módulo.
class MasMenuItem {
  final IconData icon;
  final String label;
  final String route;
  const MasMenuItem(this.icon, this.label, this.route);
}

const _masItems = <MasMenuItem>[
  MasMenuItem(Icons.access_time_rounded, 'Asistencia', '/asistencia'),
  MasMenuItem(Icons.check_box_rounded, 'Tareas', '/tareas'),
  MasMenuItem(Icons.calendar_month_rounded, 'Calendario', '/calendario'),
  MasMenuItem(Icons.notifications_rounded, 'Notificaciones', '/notificaciones'),
  MasMenuItem(Icons.person_rounded, 'Perfil', '/perfil'),
  MasMenuItem(Icons.auto_awesome_rounded, 'IA Asistente', '/ai'),
];

// ─── Estado global del sheet ─────────────────────────────────────────────────
//
// Usamos un OverlayEntry insertado en el root Overlay. Esto evita TODO
// problema con:
// - addPostFrameCallback que no dispara si no hay frame agendado.
// - showModalBottomSheet que comparte estado con el Navigator de la branch.
// - El selectedIndex del bottom nav que está en -1 cuando se está en una
//   ruta abierta desde el propio "Más".
//
// El sheet vive en su propio overlay, completamente independiente del
// sistema de routing. Se puede abrir SIEMPRE, en cualquier ruta.

OverlayEntry? _currentEntry;

/// Abre el sheet "Más" instantáneamente. Sin importar la ruta actual.
/// Si el sheet ya estaba abierto, no hace nada (evita doble inserción).
void mostrarMasSheet(BuildContext context) {
  if (_currentEntry != null) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => MasSheetOverlay(
      onClose: () => _removeEntry(entry),
    ),
  );
  _currentEntry = entry;
  overlay.insert(entry);
}

void _removeEntry(OverlayEntry entry) {
  if (entry.mounted) entry.remove();
  if (_currentEntry == entry) _currentEntry = null;
}

// ─── Overlay del sheet ───────────────────────────────────────────────────────

class MasSheetOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const MasSheetOverlay({super.key, required this.onClose});

  @override
  State<MasSheetOverlay> createState() => _MasSheetOverlayState();
}

class _MasSheetOverlayState extends State<MasSheetOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cerrar() async {
    if (_closing) return;
    _closing = true;
    await _ctrl.reverse();
    widget.onClose();
  }

  Future<void> _seleccionar(String route) async {
    if (_closing) return;
    _closing = true;
    HapticFeedback.selectionClick();
    // Guarda referencia al GoRouter ANTES de la animación; el contexto del
    // overlay no participa del árbol de navegación, así que vamos vía la
    // instancia global de GoRouter desde el primer NavigatorContext disponible.
    final router = GoRouter.maybeOf(context);
    await _ctrl.reverse();
    widget.onClose();
    router?.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim — tap fuera del sheet cierra.
          Positioned.fill(
            child: GestureDetector(
              onTap: _cerrar,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: _fade,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          // Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (_, child) {
                return FractionalTranslation(
                  translation: Offset(0, 1 - _slide.value),
                  child: child,
                );
              },
              child: _SheetBody(
                onSelect: _seleccionar,
                onClose: _cerrar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contenido visual del sheet ──────────────────────────────────────────────

class _SheetBody extends StatelessWidget {
  final void Function(String route) onSelect;
  final VoidCallback onClose;

  const _SheetBody({required this.onSelect, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Más módulos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: _masItems.length,
              itemBuilder: (_, i) {
                final item = _masItems[i];
                return _MasTile(
                  item: item,
                  onTap: () => onSelect(item.route),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MasTile extends StatelessWidget {
  final MasMenuItem item;
  final VoidCallback onTap;
  const _MasTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

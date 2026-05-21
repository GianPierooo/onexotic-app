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

/// Muestra el sheet "Más" de manera SIEMPRE inmediata, sin importar la ruta
/// actual. Usa el root navigator para que aparezca por encima del bottom nav.
void mostrarMasSheet(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const MasSheet(),
    );
  });
}

/// Bottom sheet del menú "Más". Es un StatefulWidget independiente del shell
/// para que abrir/cerrar el sheet no dispare ningún rebuild en el nav.
class MasSheet extends StatefulWidget {
  const MasSheet({super.key});

  @override
  State<MasSheet> createState() => _MasSheetState();
}

class _MasSheetState extends State<MasSheet> {
  void _abrir(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true).pop();
    // El sheet usa rootNavigator, así que volvemos al shell antes de navegar.
    // El go() vive en el ShellRoute, así llega al branch correcto.
    Future.microtask(() {
      if (!context.mounted) return;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
                  onTap: () => _abrir(context, item.route),
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

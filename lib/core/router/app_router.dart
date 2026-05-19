import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/asistencia/screens/asistencia_screen.dart';
import '../../modules/calendario/screens/calendario_screen.dart';
import '../../modules/dashboard/providers/dashboard_provider.dart';
import '../../modules/dashboard/screens/dashboard_screen.dart';
import '../../modules/disenios/screens/brief_screen.dart';
import '../../modules/disenios/screens/disenio_detalle_screen.dart';
import '../../modules/disenios/screens/disenios_screen.dart';
import '../../modules/disenios/models/disenio.dart';
import '../../modules/equipo/providers/equipo_provider.dart';
import '../../modules/equipo/screens/equipo_screen.dart';
import '../../modules/equipo/screens/perfil_miembro_screen.dart';
import '../../modules/inventario/models/producto.dart';
import '../../modules/ai_asistente/screens/ai_screen.dart';
import '../../modules/notificaciones/screens/notificaciones_screen.dart';
import '../../modules/perfil/screens/perfil_screen.dart';
import '../../modules/inventario/screens/inventario_screen.dart';
import '../../modules/inventario/screens/producto_detail_screen.dart';
import '../../modules/login/screens/login_screen.dart';
import '../../modules/tareas/models/tarea.dart';
import '../../modules/tareas/screens/tarea_detail_screen.dart';
import '../../modules/tareas/screens/tareas_screen.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: _resolveInitialLocation(),
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      if (loc == '/login') return isLoggedIn ? '/dashboard' : null;
      if (!isLoggedIn) return '/login';

      // Diseñadora no puede acceder a inventario.
      // El rol viene del userMetadata cacheado en el JWT (disponible sin query async).
      if (loc.startsWith('/inventario')) {
        final rol = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['rol'] as String?;
        if (rol == 'disenadora') return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // -- Shell con bottom navigation persistente -----------------------------
      // Branch indices:
      //   0 dashboard · 1 asistencia · 2 tareas · 3 equipo · 4 perfil
      //   5 inventario · 6 disenios · 7 calendario · 8 ai · 9 notificaciones
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // 0 · Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          // 1 · Asistencia
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/asistencia',
              builder: (_, __) => const AsistenciaScreen(),
            ),
          ]),
          // 2 · Tareas
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tareas',
              builder: (_, __) => const TareasScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final tarea = state.extra as Tarea;
                    return TareaDetailScreen(tarea: tarea);
                  },
                ),
              ],
            ),
          ]),
          // 3 · Equipo
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/equipo',
              builder: (_, __) => const EquipoScreen(),
              routes: [
                GoRoute(
                  path: 'perfil',
                  builder: (context, state) {
                    final stats = state.extra as UsuarioConStats;
                    return PerfilMiembroScreen(stats: stats);
                  },
                ),
              ],
            ),
          ]),
          // 4 · Perfil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/perfil',
              builder: (_, __) => const PerfilScreen(),
            ),
          ]),
          // 5 · Inventario
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventario',
              builder: (_, __) => const InventarioScreen(),
              routes: [
                GoRoute(
                  path: 'detalle',
                  builder: (context, state) {
                    final variantes = state.extra as List<Producto>;
                    return ProductoDetailScreen(variantes: variantes);
                  },
                ),
              ],
            ),
          ]),
          // 6 · Diseños
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/disenios',
              builder: (_, __) => const DiseniosScreen(),
              routes: [
                GoRoute(
                  path: 'nuevo-brief',
                  builder: (_, __) => const BriefScreen(),
                ),
                GoRoute(
                  path: 'detalle',
                  builder: (context, state) {
                    final d = state.extra as Disenio;
                    return DisenioDetalleScreen(disenio: d);
                  },
                ),
              ],
            ),
          ]),
          // 7 · Calendario
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendario',
              builder: (_, __) => const CalendarioScreen(),
            ),
          ]),
          // 8 · IA Asistente
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ai',
              builder: (_, __) => const AiScreen(),
            ),
          ]),
          // 9 · Notificaciones
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notificaciones',
              builder: (_, __) => const NotificacionesScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

String _resolveInitialLocation() {
  final session = Supabase.instance.client.auth.currentSession;
  return session != null ? '/dashboard' : '/login';
}

// --- Nav item definition -------------------------------------------------------

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branchIndex; // -1 = opens "Más" sheet
  const _NavItem(this.icon, this.activeIcon, this.label, this.branchIndex);
}

class _MasItem {
  final IconData icon;
  final String label;
  final int branchIndex;
  const _MasItem(this.icon, this.label, this.branchIndex);
}

// --- AppShell -----------------------------------------------------------------

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  // -- Nav items por rol --------------------------------------------------------
  static const _ceoNavItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio', 0),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventario', 5),
    _NavItem(Icons.brush_outlined, Icons.brush_rounded, 'Diseños', 6),
    _NavItem(Icons.group_outlined, Icons.group_rounded, 'Equipo', 3),
    _NavItem(Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'Más', -1),
  ];

  static const _disenadoraNavItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio', 0),
    _NavItem(Icons.brush_outlined, Icons.brush_rounded, 'Mis Diseños', 6),
    _NavItem(Icons.check_box_outlined, Icons.check_box_rounded, 'Tareas', 2),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendario', 7),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil', 4),
  ];

  static const _rrhhNavItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio', 0),
    _NavItem(Icons.access_time, Icons.access_time_filled, 'Asistencia', 1),
    _NavItem(Icons.group_outlined, Icons.group_rounded, 'Equipo', 3),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendario', 7),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil', 4),
  ];

  static const _produccionNavItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio', 0),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventario', 5),
    _NavItem(Icons.check_box_outlined, Icons.check_box_rounded, 'Tareas', 2),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendario', 7),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil', 4),
  ];

  // -- CEO "Más" items ----------------------------------------------------------
  static const _masItems = <_MasItem>[
    _MasItem(Icons.access_time_rounded, 'Asistencia', 1),
    _MasItem(Icons.check_box_rounded, 'Tareas', 2),
    _MasItem(Icons.calendar_month_rounded, 'Calendario', 7),
    _MasItem(Icons.notifications_rounded, 'Notificaciones', 9),
    _MasItem(Icons.person_rounded, 'Perfil', 4),
    _MasItem(Icons.auto_awesome_rounded, 'IA Asistente', 8),
  ];

  // Branches que pertenecen al "Más" del CEO
  static const _ceoBranchesEnMas = {1, 2, 4, 7, 8, 9};

  List<_NavItem> _navItems(String rol) => switch (rol) {
    'ceo'        => _ceoNavItems,
    'disenadora' => _disenadoraNavItems,
    'rrhh'       => _rrhhNavItems,
    'produccion' => _produccionNavItems,
    _            => _ceoNavItems,
  };

  int _currentNavPos(String rol, int branchIndex) {
    final items = _navItems(rol);
    for (int i = 0; i < items.length; i++) {
      if (items[i].branchIndex == branchIndex) return i;
    }
    if (rol == 'ceo' && _ceoBranchesEnMas.contains(branchIndex)) return 4;
    return 0;
  }

  void _onNavTap(BuildContext context, String rol, int navPos) {
    final item = _navItems(rol)[navPos];
    if (item.branchIndex == -1) {
      _showMasSheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      item.branchIndex,
      initialLocation: item.branchIndex == navigationShell.currentIndex,
    );
  }

  void _showMasSheet(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _MasSheet(
          items: _masItems,
          currentBranchIndex: navigationShell.currentIndex,
          onSelect: (branchIndex) {
            Navigator.pop(context);
            HapticFeedback.selectionClick();
            navigationShell.goBranch(
              branchIndex,
              initialLocation: branchIndex == navigationShell.currentIndex,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? 'ceo',
      orElse: () => 'ceo',
    );

    final items = _navItems(rol);
    final currentPos = _currentNavPos(rol, navigationShell.currentIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _OnExoticBottomNav(
        items: items,
        currentIndex: currentPos,
        onTap: (i) => _onNavTap(context, rol, i),
      ),
    );
  }
}

// --- "Más" bottom sheet --------------------------------------------------------

class _MasSheet extends StatelessWidget {
  final List<_MasItem> items;
  final int currentBranchIndex;
  final ValueChanged<int> onSelect;

  const _MasSheet({
    required this.items,
    required this.currentBranchIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
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
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isActive = item.branchIndex == currentBranchIndex;
                return _MasTile(
                  item: item,
                  isActive: isActive,
                  onTap: () => onSelect(item.branchIndex),
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
  final _MasItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _MasTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
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

// --- Bottom navigation bar ----------------------------------------------------

class _OnExoticBottomNav extends StatelessWidget {
  const _OnExoticBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: _NavButton(
                item: items[i],
                active: active,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 2,
            width: active ? 28 : 0,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              active ? item.activeIcon : item.icon,
              key: ValueKey(active),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';

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
import '../../modules/chat/providers/chat_provider.dart';
import '../../modules/chat/screens/chat_screen.dart';
import '../../modules/equipo/models/usuario.dart';
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
import '../fcm/pending_route_notifier.dart';
import '../theme/app_colors.dart';
import 'mas_sheet.dart';

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
                GoRoute(
                  path: 'chat',
                  builder: (context, state) {
                    final otro = state.extra as Usuario;
                    return ChatScreen(otro: otro);
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

// --- AppShell -----------------------------------------------------------------

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Si FcmService ya depositó una ruta (cold start), la consumimos en cuanto
    // el primer frame esté pintado. Después escuchamos cambios futuros.
    if (pendingRouteNotifier.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingRoute());
    }
    pendingRouteNotifier.addListener(_onPendingRouteChanged);
  }

  @override
  void dispose() {
    pendingRouteNotifier.removeListener(_onPendingRouteChanged);
    super.dispose();
  }

  void _onPendingRouteChanged() {
    if (pendingRouteNotifier.value == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingRoute());
  }

  void _consumePendingRoute() {
    final ruta = pendingRouteNotifier.value;
    if (ruta == null) return;
    if (!mounted) return;
    pendingRouteNotifier.value = null;
    context.go(ruta);
  }

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

  List<_NavItem> _navItems(String rol) => switch (rol) {
    'ceo'        => _ceoNavItems,
    'disenadora' => _disenadoraNavItems,
    'rrhh'       => _rrhhNavItems,
    'produccion' => _produccionNavItems,
    _            => _ceoNavItems,
  };

  /// Devuelve la posición del nav item para el branch actual.
  /// Si el branch no corresponde a ningún item visible (ej. rutas del sheet
  /// "Más"), retorna -1 → ningún item queda marcado como seleccionado.
  int _currentNavPos(String rol, int branchIndex) {
    final items = _navItems(rol);
    for (int i = 0; i < items.length; i++) {
      if (items[i].branchIndex == branchIndex) return i;
    }
    return -1;
  }

  void _onNavTap(String rol, int navPos) {
    final item = _navItems(rol)[navPos];
    if (item.branchIndex == -1) {
      // Botón "Más" → abre sheet SIEMPRE, sin condición de ruta actual.
      mostrarMasSheet(context);
      return;
    }
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      item.branchIndex,
      initialLocation: item.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? 'ceo',
      orElse: () => 'ceo',
    );

    final items = _navItems(rol);
    final currentPos = _currentNavPos(rol, widget.navigationShell.currentIndex);
    // Para los roles cuya nav incluye Equipo, el badge va ahí (branch 3).
    // Para los demás (diseñadora/producción) va en el botón "Más" (branch -1).
    final badgeTargetBranch =
        items.any((i) => i.branchIndex == 3) ? 3 : -1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: _OnExoticBottomNav(
        items: items,
        currentIndex: currentPos,
        badgeTargetBranch: badgeTargetBranch,
        onTap: (i) => _onNavTap(rol, i),
      ),
    );
  }
}

// --- Floating pill bottom navigation ------------------------------------------

class _OnExoticBottomNav extends ConsumerWidget {
  const _OnExoticBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.badgeTargetBranch,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Branch al que se le pega el badge de mensajes no leídos.
  final int badgeTargetBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El badge se suscribe DENTRO de la nav para que cuando llegue un mensaje
    // solo se rebuildee este subárbol — no AppShell entero (que arrastra
    // todo el body por dentro).
    final unreadTotal = ref.watch(totalUnreadProvider);
    final badges = unreadTotal > 0
        ? <int, int>{badgeTargetBranch: unreadTotal}
        : const <int, int>{};
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Transparent outer shell — gives the nav its height slot in the Scaffold.
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              // Slight frosted tint — works for both dark and light themes.
              color: AppColors.navBackground.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.75,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemW = constraints.maxWidth / items.length;
                // Cuando estamos en una ruta del sheet "Más" no hay item
                // seleccionado (currentIndex = -1) → ocultamos el pill para
                // que ningún botón parezca activo.
                final showPill = currentIndex >= 0;
                final pillLeft = (currentIndex < 0 ? 0 : currentIndex) * itemW + 10;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Animated pill indicator ──────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: 9,
                      bottom: 9,
                      width: itemW - 20,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: showPill ? 1 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Nav buttons row ──────────────────────────────────
                    Row(
                      children: List.generate(items.length, (i) => Expanded(
                        child: _NavButton(
                          item: items[i],
                          active: i == currentIndex,
                          badge: badges[items[i].branchIndex] ?? 0,
                          onTap: () => onTap(i),
                        ),
                      )),
                    ),
                  ],
                );
              },
            ),
          ),
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
    this.badge = 0,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey(active),
                  size: 20,
                  color: color,
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.navBackground,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: 0.2,
            ),
            child: Text(item.label, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

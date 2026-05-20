import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/notificaciones_provider.dart';
import '../widgets/notificacion_item.dart';

class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  static const _filtros = <(String, String)>[
    ('todas',      'Todas'),
    ('disenio',    'Diseños'),
    ('tarea',      'Tareas'),
    ('inventario', 'Inventario'),
    ('sistema',    'Sistema'),
  ];

  String _mensajeError(Object e) {
    final msg = e.toString();
    // Muestra el mensaje completo para diagnóstico
    if (kDebugMode) print('[NotificacionesScreen] ERROR COMPLETO: $msg');
    if (msg.contains('JWT') || msg.contains('401') || msg.contains('auth')) {
      return 'Sesión expirada.\nCierra sesión y vuelve a entrar.\n\n$msg';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'Sin conexión a internet.\n\n$msg';
    }
    return msg;
  }

  void _navegar(BuildContext context, WidgetRef ref, Notificacion notif) {
    if (!notif.leido) {
      ref.read(marcarLeidaProvider.notifier).marcar(notif.id);
    }
    final ruta = switch (notif.tipo) {
      'disenio'    => '/disenios',
      'tarea'      => '/tareas',
      'inventario' => '/inventario',
      'asistencia' => '/asistencia',
      'bono'       => '/equipo',
      _            => null,
    };
    if (ruta != null) context.go(ruta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa stream (Realtime) como fuente primaria · es lo mismo que usa el badge.
    // Cae al FutureProvider si el stream aún no emitió (primer frame de carga).
    final streamAsync = ref.watch(notificacionesStreamProvider);
    final fallbackAsync = ref.watch(notificacionesAllProvider);

    // Extrae lista efectiva priorizando cualquier dato disponible.
    // Si el stream tiene value (aunque esté loading/error), úsalo.
    // Esto evita el bug donde badge muestra "1 sin leer" pero lista vacía
    // porque .when(data: ...) no se llama en estado loading-with-previous-data.
    final List<Notificacion>? notifsData =
        streamAsync.valueOrNull ?? fallbackAsync.valueOrNull;
    final bool isLoading = notifsData == null &&
        (streamAsync.isLoading || fallbackAsync.isLoading);
    final Object? errorObj = (notifsData == null)
        ? (streamAsync.error ?? fallbackAsync.error)
        : null;

    final filtro = ref.watch(filtroNotifProvider);
    final marcarState = ref.watch(marcarTodasProvider);
    final isMarking = marcarState is AsyncLoading;

    final sinLeer = notifsData?.where((x) => !x.leido).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notificaciones',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (sinLeer > 0)
              Text(
                '$sinLeer sin leer',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (notifsData != null && notifsData.any((n) => !n.leido))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: isMarking
                    ? null
                    : () => ref
                        .read(marcarTodasProvider.notifier)
                        .marcarTodas(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isMarking ? 'Marcando...' : 'Marcar leídas',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isMarking ? AppColors.textTertiary : AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // -- Filter pills ---------------------------------------------------
          _FilterPills(filtros: _filtros, filtroActivo: filtro),
          const SizedBox(height: 4),

          // -- Contenido ------------------------------------------------------
          Expanded(
            child: Builder(builder: (_) {
              if (notifsData == null && isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                );
              }
              if (notifsData == null && errorObj != null) {
                return _ErrorView(
                  mensaje: _mensajeError(errorObj),
                  onReintentar: () =>
                      ref.invalidate(notificacionesAllProvider),
                );
              }

              final allNotifs = notifsData ?? const <Notificacion>[];
              final notifs = filtro == 'todas'
                  ? allNotifs
                  : allNotifs.where((n) => n.tipo == filtro).toList();

              if (notifs.isEmpty) {
                return _EmptyState(
                  mensaje: allNotifs.isEmpty
                      ? 'Todo al día · No hay notificaciones'
                      : 'Sin notificaciones de este tipo',
                );
              }

              final nuevas = notifs.where((n) => !n.leido).toList();
              final anteriores = notifs.where((n) => n.leido).toList();

              // Construye la lista plana para ListView.builder.
              // Cada entrada es un widget o un descriptor de notif.
              final List<_RowSpec> rows = [];
              if (nuevas.isNotEmpty) {
                rows.add(_RowSpec.label('NUEVAS', nuevas.length, true));
                for (var i = 0; i < nuevas.length; i++) {
                  rows.add(_RowSpec.item(nuevas[i], i, isNew: true));
                }
                rows.add(_RowSpec.gap(16));
              }
              if (anteriores.isNotEmpty) {
                rows.add(_RowSpec.label('ANTERIORES', anteriores.length, false));
                for (var i = 0; i < anteriores.length; i++) {
                  rows.add(_RowSpec.item(anteriores[i], i, isNew: false));
                }
              }

              return RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface2,
                onRefresh: () async {
                  ref.invalidate(notificacionesAllProvider);
                  await ref
                      .read(notificacionesAllProvider.future)
                      .catchError((_) => <Notificacion>[]);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    try {
                      if (row.kind == _RowKind.label) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: _SectionLabel(
                            row.label!,
                            row.count,
                            accentBadge: row.accent ?? false,
                          ),
                        );
                      }
                      if (row.kind == _RowKind.gap) {
                        return SizedBox(height: row.gap ?? 8);
                      }
                      // item
                      final notif = row.notif!;
                      final widget = NotificacionItem(
                        key: ValueKey('notif-${notif.id}-${row.index}'),
                        notif: notif,
                        index: row.index ?? 0,
                        onTap: () => _navegar(context, ref, notif),
                      );
                      return (row.isNew == true)
                          ? widget
                          : Opacity(opacity: 0.7, child: widget);
                    } catch (e, st) {
                      if (kDebugMode) print('[notif list] error en item $i: $e');
                      if (kDebugMode) print('$st');
                      return _BrokenItem(error: e.toString());
                    }
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// --- Filter pills -------------------------------------------------------------

class _FilterPills extends ConsumerWidget {
  final List<(String, String)> filtros;
  final String filtroActivo;

  const _FilterPills(
      {required this.filtros, required this.filtroActivo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = filtros[i];
          final isActive = filtroActivo == value;
          return GestureDetector(
            onTap: () =>
                ref.read(filtroNotifProvider.notifier).state = value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Section label ------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;
  final bool accentBadge;

  const _SectionLabel(this.label, this.count, {this.accentBadge = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        if (count != null && accentBadge) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ] else if (count != null) ...[
          const SizedBox(width: 5),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

// --- Empty state --------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String mensaje;

  const _EmptyState({this.mensaje = 'Todo al día · No hay notificaciones'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Error view ---------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las notificaciones',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                mensaje,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reintentar',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Broken item placeholder (renderiza si un item de la lista falló) ---------

class _BrokenItem extends StatelessWidget {
  final String error;
  const _BrokenItem({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.error.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notificación con error de formato',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Row spec para ListView.builder -------------------------------------------

enum _RowKind { label, item, gap }

class _RowSpec {
  final _RowKind kind;
  final String? label;
  final int? count;
  final bool? accent;
  final Notificacion? notif;
  final int? index;
  final bool? isNew;
  final double? gap;

  const _RowSpec._({
    required this.kind,
    this.label,
    this.count,
    this.accent,
    this.notif,
    this.index,
    this.isNew,
    this.gap,
  });

  factory _RowSpec.label(String label, int count, bool accent) =>
      _RowSpec._(
        kind: _RowKind.label,
        label: label,
        count: count,
        accent: accent,
      );

  factory _RowSpec.item(Notificacion notif, int index, {required bool isNew}) =>
      _RowSpec._(
        kind: _RowKind.item,
        notif: notif,
        index: index,
        isNew: isNew,
      );

  factory _RowSpec.gap(double gap) =>
      _RowSpec._(kind: _RowKind.gap, gap: gap);
}

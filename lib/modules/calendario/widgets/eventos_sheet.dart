import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/calendario_provider.dart';
import '../screens/evento_detalle_sheet.dart';
import '../screens/nuevo_evento_sheet.dart';
import 'evento_item.dart';

class EventosSheet extends ConsumerWidget {
  final DateTime fecha;
  final List<EventoCalendario> eventos;

  const EventosSheet({
    super.key,
    required this.fecha,
    required this.eventos,
  });

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  bool _esHoy(DateTime d) {
    final hoy = DateTime.now();
    return d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
  }

  String _formatFecha(DateTime d) {
    final prefix = _esHoy(d) ? 'Hoy · ' : '';
    return '$prefix${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';
  }

  void _abrirNuevoEvento(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NuevoEventoSheet(fechaInicial: fecha),
      );
    });
  }

  void _abrirDetalle(BuildContext context, EventoCalendario evento) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EventoDetalleSheet(evento: evento),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
        data: (u) => u?['rol'] as String? ?? '', orElse: () => '');
    final isCeo = rol == 'ceo' || rol == 'manager';

    // Watch provider for live updates (e.g. after creating a new event from the sheet)
    final eventosAsync = ref.watch(calendarioEventosProvider);
    final key = DateTime(fecha.year, fecha.month, fecha.day);
    final eventosActuales = eventosAsync.maybeWhen(
      data: (mapa) => mapa[key] ?? [],
      orElse: () => eventos,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderHover,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFecha(fecha),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          eventosActuales.isEmpty
                              ? 'Sin eventos · Toca + para agregar'
                              : '${eventosActuales.length} evento${eventosActuales.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón "+" solo para CEO
                  if (isCeo)
                    GestureDetector(
                      onTap: () => _abrirNuevoEvento(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: AppColors.border, height: 1),

            // ── Lista de eventos ──────────────────────────────────────────
            Expanded(
              child: eventosActuales.isEmpty
                  ? _EmptyState(isCeo: isCeo, onAgregar: () => _abrirNuevoEvento(context))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: eventosActuales.length,
                      itemBuilder: (_, i) => EventoItem(
                        evento: eventosActuales[i],
                        onTap: () => _abrirDetalle(context, eventosActuales[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isCeo;
  final VoidCallback onAgregar;
  const _EmptyState({required this.isCeo, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'Sin eventos este día',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          if (isCeo) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onAgregar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('Agregar evento',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

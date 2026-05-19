import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/calendario_provider.dart';
import 'nuevo_evento_sheet.dart';

class EventoDetalleSheet extends ConsumerWidget {
  final EventoCalendario evento;

  const EventoDetalleSheet({super.key, required this.evento});

  String _formatFecha(DateTime d) =>
      DateFormat("EEEE, d 'de' MMMM yyyy", 'es').format(d);

  String _formatHora(TimeOfDay h) =>
      '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.maybeWhen(
        data: (u) => u?['rol'] as String? ?? '', orElse: () => '');
    final isCeo = rol == 'ceo' || rol == 'manager';
    final isLoading = ref.watch(eliminarEventoProvider) is AsyncLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip de tipo
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: evento.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _labelTipo(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: evento.color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Título
          Text(
            evento.titulo,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Fecha
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: _formatFecha(evento.fecha),
          ),

          // Hora
          if (evento.hora != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time_rounded,
              text: _formatHora(evento.hora!),
            ),
          ],

          // Lugar
          if (evento.lugar != null && evento.lugar!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: evento.lugar!,
            ),
          ],

          // Descripción
          if (evento.descripcion != null && evento.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              evento.descripcion!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Acciones
          if (evento.esEditable && isCeo) ...[
            // Editar
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Abre el sheet de edición encima del de detalle (evita
                  // usar context tras pop). Cuando el usuario guarda,
                  // NuevoEventoSheet retorna true y cerramos el detalle.
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!context.mounted) return;
                    final ok = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => NuevoEventoSheet(eventoEditar: evento),
                    );
                    if (ok == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface2,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('Editar evento',
                    style: GoogleFonts.inter(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            // Eliminar
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final ok = await _confirmarEliminar(context);
                        if (ok == true && context.mounted) {
                          await ref
                              .read(eliminarEventoProvider.notifier)
                              .eliminar(evento.id);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.error.withValues(alpha: 0.12),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.error))
                    : const Icon(Icons.delete_outlined, size: 16),
                label: Text('Eliminar evento',
                    style: GoogleFonts.inter(fontSize: 14)),
              ),
            ),
          ] else if (!evento.esEditable && evento.rutaModulo.isNotEmpty) ...[
            // Ver en módulo correspondiente
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(evento.rutaModulo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: evento.color.withValues(alpha: 0.12),
                  foregroundColor: evento.color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                    'Ver en ${_labelModulo()}',
                    style: GoogleFonts.inter(fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _labelTipo() {
    if (evento.esEditable) {
      return (evento.tipoDb ?? 'Evento especial').toUpperCase();
    }
    return switch (evento.tipo) {
      'drop'    => 'LANZAMIENTO DE DROP',
      'reunion' => 'REUNIÓN',
      'tarea'   => 'TAREA',
      'disenio' => 'DISEÑO',
      _         => evento.tipo.toUpperCase(),
    };
  }

  String _labelModulo() => switch (evento.tipo) {
        'drop'    => 'Inventario',
        'reunion' => 'Asistencia',
        'tarea'   => 'Tareas',
        'disenio' => 'Diseños',
        _         => 'módulo',
      };

  Future<bool?> _confirmarEliminar(BuildContext context) async {
    await Future.microtask(() {});
    if (!context.mounted) return null;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('¿Eliminar evento?',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text('Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar',
                style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

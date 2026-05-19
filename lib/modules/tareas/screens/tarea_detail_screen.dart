import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/tarea.dart';
import '../providers/tareas_provider.dart';
import '../widgets/area_badge.dart';
import '../widgets/prioridad_badge.dart';

class TareaDetailScreen extends ConsumerWidget {
  final Tarea tarea;
  const TareaDetailScreen({super.key, required this.tarea});

  void _abrirImagenFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
              errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48),
            ),
          ),
        ),
      ),
    ));
  }

  String _formatFecha(DateTime d) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${d.day} de ${meses[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleState = ref.watch(toggleTareaProvider);
    final isLoading = toggleState is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tareas');
            }
          },
        ),
        title: Text(
          'Detalle de tarea',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              tarea.titulo,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: tarea.completado
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Badges
            Row(
              children: [
                AreaBadge(area: tarea.area),
                const SizedBox(width: 8),
                PrioridadBadge(prioridad: tarea.prioridad),
                if (tarea.completado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Completada',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Descripción
            if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
              const _Label('DESCRIPCIÓN'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tarea.descripcion!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Asignado a
            if (tarea.asignadoA != null) ...[
              const _Label('ASIGNADO A'),
              const SizedBox(height: 8),
              _AsignadoTile(userId: tarea.asignadoA!),
              const SizedBox(height: 20),
            ],

            // Fecha límite
            if (tarea.fechaLimite != null) ...[
              const _Label('FECHA LÍMITE'),
              const SizedBox(height: 8),
              Builder(builder: (ctx) {
                final hoy = DateTime.now();
                final diff = tarea.fechaLimite!
                    .difference(DateTime(hoy.year, hoy.month, hoy.day))
                    .inDays;
                final vencida = diff < 0;
                return Row(
                  children: [
                    Icon(
                      vencida
                          ? Icons.error_outline_rounded
                          : Icons.calendar_today_outlined,
                      size: 16,
                      color: vencida ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFecha(tarea.fechaLimite!),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            vencida ? FontWeight.w600 : FontWeight.w400,
                        color: vencida
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (vencida) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Vencida',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 24),
            ],

            // Imagen adjunta
            if (tarea.imagenUrl != null) ...[
              const _Label('IMAGEN ADJUNTA'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _abrirImagenFullscreen(context, tarea.imagenUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: tarea.imagenUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppColors.surface2,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.surface2,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.textTertiary, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Toca para ver completa',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 8),

            // Botón completar
            if (!tarea.completado)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await ref.read(toggleTareaProvider.notifier).toggle(
                                tarea.id,
                                completado: true,
                              );
                          if (context.mounted) context.pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    'Marcar como completada',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile del asignado ─────────────────────────────────────────────────────────

class _AsignadoTile extends ConsumerWidget {
  final String userId;
  const _AsignadoTile({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('users')
          .select('nombre, rol')
          .eq('id', userId)
          .maybeSingle(),
      builder: (context, snap) {
        final user = snap.data;
        final nombre = user?['nombre'] as String? ?? 'Usuario';
        final rol = user?['rol'] as String? ?? '';

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (rol.isNotEmpty)
                  Text(
                    rol.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }
}

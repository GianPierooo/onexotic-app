import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/tareas_provider.dart';
import 'area_badge.dart';

class FiltroPills extends ConsumerWidget {
  const FiltroPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(tareasFiltroProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Estado
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final estado in ['todas', 'mis_tareas', 'completadas'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Pill(
                    label: _labelEstado(estado),
                    activo: filtro.estado == estado,
                    onTap: () => ref
                        .read(tareasFiltroProvider.notifier)
                        .update((f) => f.copyWith(estado: estado)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Fila 2: Área
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pill(
                  label: 'Todas',
                  activo: filtro.area == null,
                  onTap: () => ref
                      .read(tareasFiltroProvider.notifier)
                      .update((f) => f.copyWith(clearArea: true)),
                ),
              ),
              for (final area in [
                'tech',
                'disenio',
                'marketing',
                'produccion',
                'rrhh',
                'legal',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AreaPill(
                    area: area,
                    activo: filtro.area == area,
                    onTap: () => ref
                        .read(tareasFiltroProvider.notifier)
                        .update((f) => f.copyWith(area: area)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelEstado(String e) => switch (e) {
        'todas'       => 'Todas',
        'mis_tareas'  => 'Mis tareas',
        'completadas' => 'Completadas',
        _             => e,
      };
}

class _Pill extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? AppColors.accent : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AreaPill extends StatelessWidget {
  final String area;
  final bool activo;
  final VoidCallback onTap;

  const _AreaPill({
    required this.area,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final areaColor = AreaBadge.colorForArea(area);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo
              ? areaColor.withValues(alpha: 0.18)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo
                ? areaColor.withValues(alpha: 0.5)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          AreaBadge.labelForArea(area),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? areaColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

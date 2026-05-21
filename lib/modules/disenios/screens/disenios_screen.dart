import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_fab.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/disenios_provider.dart';
import '../widgets/disenio_card.dart';

class DiseniosScreen extends ConsumerWidget {
  const DiseniosScreen({super.key});

  static const _tabs = [
    ('todos',     'Todos'),
    ('brief',     'Brief'),
    ('proceso',   'En proceso'),
    ('avance',    'Avance'),
    ('revision',  'Revisión'),
    ('aprobado',  'Aprobados'),
    ('rechazado', 'Rechazados'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diseniosAsync = ref.watch(diseniosProvider);
    final revAsync = ref.watch(revisionesPendientesProvider);
    final userAsync = ref.watch(currentUserProvider);

    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? '',
      orElse: () => '',
    );
    final isCeo = rol == 'ceo' || rol == 'manager';
    final isDisenadora = rol == 'disenadora';
    final revisiones = revAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: (isCeo || isDisenadora)
            ? AppFab(onPressed: () => context.push('/disenios/nuevo-brief'))
            : null,
        body: Stack(
          children: [
            const OnboardingLauncher(
              modulo: 'disenios',
              slides: GuiasContent.disenios,
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Diseños',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const GuiaHelpButton(slides: GuiasContent.disenios),
                      ],
                    ),
                    // Alerta de revisiones pendientes para CEO
                    if (isCeo && revisiones > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              '$revisiones ${revisiones == 1 ? 'diseño espera' : 'diseños esperan'} tu aprobación',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // ── Tabs scrolleables ────────────────────────────────────────
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.accent,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.border,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                onTap: (i) => ref
                    .read(diseniosTabProvider.notifier)
                    .state = _tabs[i].$1,
                tabs: _tabs
                    .map((t) => Tab(
                          text: t.$2,
                          height: 36,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 8),

              // ── Lista ────────────────────────────────────────────────────
              Expanded(
                child: diseniosAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                  error: (e, _) => _ErrorCard('$e'),
                  data: (disenios) {
                    if (disenios.isEmpty) return const _EmptyState();
                    return RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface2,
                      onRefresh: () async {
                        ref.invalidate(diseniosProvider);
                        ref.invalidate(revisionesPendientesProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: disenios.length,
                        itemBuilder: (_, i) => DisenioCard(
                          key: ValueKey(disenios[i].id),
                          disenio: disenios[i],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.brush_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay diseños en esta categoría',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

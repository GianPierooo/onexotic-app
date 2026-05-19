import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/equipo_provider.dart';
import '../providers/presence_provider.dart';
import '../widgets/bonos_card.dart';
import '../widgets/miembro_card.dart';
import 'registrar_miembro_bottom_sheet.dart';

class EquipoScreen extends ConsumerWidget {
  const EquipoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipoAsync = ref.watch(equipoProvider);
    final userAsync = ref.watch(currentUserProvider);
    final onlineIds = ref.watch(onlineUserIdsProvider).valueOrNull ?? {};
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    final rol = userAsync.maybeWhen(
      data: (u) => u?['rol'] as String? ?? '',
      orElse: () => '',
    );
    final canManage = rol == 'ceo' || rol == 'rrhh';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'equipo',
            slides: GuiasContent.equipo,
          ),
          SafeArea(
            child: equipoAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.error),
            ),
          ),
          data: (miembros) {
            // Cuenta usuarios online usando Realtime Presence.
            // Si onlineIds está vacío (canal no conectado aún), fallback al usuario actual.
            final online = onlineIds.isNotEmpty
                ? miembros.where((m) => onlineIds.contains(m.usuario.id)).length
                : miembros.where((m) => m.usuario.id == currentUserId).length;

            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface2,
              onRefresh: () async {
                ref.invalidate(equipoProvider);
                ref.invalidate(bonosProvider);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Equipo',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${miembros.length} miembros · $online online ahora',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            GestureDetector(
                              onTap: () {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!context.mounted) return;
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        const RegistrarMiembroBottomSheet(),
                                  );
                                });
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          const GuiaHelpButton(slides: GuiasContent.equipo),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Lista de miembros ────────────────────────────────
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => MiembroCard(
                          key: ValueKey(miembros[i].usuario.id),
                          stats: miembros[i],
                          isOnline: onlineIds.contains(miembros[i].usuario.id),
                          onTap: () => context.push(
                            '/equipo/perfil',
                            extra: miembros[i],
                          ),
                        ),
                        childCount: miembros.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Card Bonos (siempre visible, nunca cortada) ──────
                  if (canManage)
                    const SliverToBoxAdapter(
                      child: BonosCard(),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ),
        ],
      ),
    );
  }
}

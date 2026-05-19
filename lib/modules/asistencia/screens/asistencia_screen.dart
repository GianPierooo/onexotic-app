import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../providers/asistencia_provider.dart';
import '../providers/reuniones_provider.dart';
import '../widgets/mini_calendario_semanal.dart';
import '../widgets/reunion_card.dart';
import 'crear_reunion_bottom_sheet.dart';

class AsistenciaScreen extends ConsumerWidget {
  const AsistenciaScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(reunionDeHoyProvider);
    ref.invalidate(reunionHoyProvider);
    ref.invalidate(semanaAsistenciaProvider);
    ref.invalidate(historialProvider);
  }

  String _formatFechaHoy() {
    final now = DateTime.now();
    return DateFormat("EEEE, d 'de' MMMM", 'es').format(now);
  }

  bool _esCeo() {
    // Verificar rol desde sesión actual (sin provider adicional)
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final rol = meta?['rol'] as String?;
    return rol == 'ceo' || rol == null; // null = fallback seguro
  }

  void _abrirCrearReunion(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CrearReunionBottomSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reunionDeHoyAsync = ref.watch(reunionDeHoyProvider);
    final historialAsync = ref.watch(historialProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _esCeo()
          ? FloatingActionButton(
              onPressed: () => _abrirCrearReunion(context),
              backgroundColor: AppColors.accent,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 26),
            )
          : null,
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'asistencia',
            slides: GuiasContent.asistencia,
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface2,
              onRefresh: () => _refresh(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────────────────────
                  SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistencia',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatFechaHoy(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const GuiaHelpButton(slides: GuiasContent.asistencia),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),

              // ── Contenido ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Reunión de hoy
                    const _SectionLabel('REUNION DE HOY'),
                    const SizedBox(height: 12),
                    reunionDeHoyAsync.when(
                      loading: () => const _LoadingCard(height: 280),
                      error: (e, _) => _ErrorCard('$e'),
                      data: (reunion) => reunion == null
                          ? _EmptyReunion(esCeo: _esCeo(),
                              onCrear: () => _abrirCrearReunion(context))
                          : _ReunionConAsistencia(reunion: reunion),
                    ),

                    const SizedBox(height: 28),

                    // Mini calendario semanal
                    const MiniCalendarioSemanal(),

                    const SizedBox(height: 28),

                    // Historial
                    const _SectionLabel('HISTORIAL'),
                    const SizedBox(height: 12),
                    historialAsync.when(
                      loading: () => const _LoadingCard(height: 100),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) => items.isEmpty
                          ? const SizedBox.shrink()
                          : _HistorialList(items: items),
                    ),

                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}

// ─── Sección historial ─────────────────────────────────────────────────────────

class _HistorialList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _HistorialList({required this.items});

  String _formatFecha(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return DateFormat("EEE d 'de' MMM", 'es').format(d);
    } catch (_) {
      return isoDate;
    }
  }

  String _labelTipo(String tipo) => switch (tipo) {
        'diaria'          => 'Reunión diaria',
        'semanal'         => 'Reunión semanal',
        'extraordinaria'  => 'Reunión extraordinaria',
        _                 => tipo,
      };

  Color _pctColor(double pct) {
    if (pct >= 90) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _HistorialItem(
              fecha: _formatFecha(items[i]['fecha'] as String),
              tipo: _labelTipo(items[i]['tipo'] as String),
              presentes: items[i]['presentes'] as int,
              total: items[i]['total'] as int,
              color: _pctColor(
                items[i]['total'] > 0
                    ? (items[i]['presentes'] as int) /
                            (items[i]['total'] as int) *
                            100
                    : 0,
              ),
            ),
            if (i < items.length - 1)
              Divider(height: 1, thickness: 1, color: AppColors.border, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _HistorialItem extends StatelessWidget {
  final String fecha;
  final String tipo;
  final int presentes;
  final int total;
  final Color color;

  const _HistorialItem({
    required this.fecha,
    required this.tipo,
    required this.presentes,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (presentes / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  fecha,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$presentes/$total',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _EmptyReunion extends StatelessWidget {
  final bool esCeo;
  final VoidCallback onCrear;
  const _EmptyReunion({required this.esCeo, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined,
              size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No hay reunión programada hoy',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          if (esCeo) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onCrear,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('Crear reunión',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent)),
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

// Widget que carga la asistencia por reunion_id
class _ReunionConAsistencia extends ConsumerWidget {
  final Reunion reunion;
  const _ReunionConAsistencia({required this.reunion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asistenciaAsync =
        ref.watch(asistenciaReunionProvider(reunion.id));

    return asistenciaAsync.when(
      loading: () => const _LoadingCard(height: 280),
      error: (e, _) => _ErrorCard('$e'),
      data: (data) => ReunionCard(data: data, reunion: reunion),
    );
  }
}

import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/avance.dart';
import '../models/brief.dart';
import '../models/disenio.dart';
import '../models/historial.dart';
import '../providers/avances_provider.dart';
import '../providers/briefs_provider.dart';
import '../providers/disenios_provider.dart';
import '../providers/historial_provider.dart';
import '../widgets/color_chip.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_progress_bar.dart';
import 'crear_producto_desde_disenio_sheet.dart';

class DisenioDetalleScreen extends ConsumerWidget {
  final Disenio disenio;
  const DisenioDetalleScreen({super.key, required this.disenio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disenioAsync = ref.watch(disenioDetalleProvider(disenio.id));
    final briefAsync = ref.watch(briefDeDisenioProvider(disenio.id));
    final avancesAsync = ref.watch(avancesDeDisenioProvider(disenio.id));
    final historialAsync = ref.watch(historialDeDisenioProvider(disenio.id));
    final userAsync = ref.watch(currentUserProvider);

    final d = disenioAsync.maybeWhen(data: (v) => v, orElse: () => null) ??
        disenio;
    final rol = userAsync.maybeWhen(
        data: (u) => u?['rol'] as String? ?? '', orElse: () => '');
    final userId = userAsync.maybeWhen(
        data: (u) => u?['id'] as String?, orElse: () => null);
    final isCeo = rol == 'ceo' || rol == 'manager';
    final esMiDisenio = userId == d.disenadoraId;
    final brief = briefAsync.maybeWhen(data: (b) => b, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/disenios');
            }
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(d.titulo,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            EstadoChip(estado: d.estado),
            const SizedBox(width: 6),
            _VersionBadge(d.version),
          ],
        ),
        actions: [
          if (isCeo)
            _CeoMenuButton(disenio: d),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface2,
        onRefresh: () async {
          ref.invalidate(disenioDetalleProvider(d.id));
          ref.invalidate(avancesDeDisenioProvider(d.id));
          ref.invalidate(historialDeDisenioProvider(d.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Barra de progreso ────────────────────────────────────────
              EstadoProgressBar(estado: d.estado),
              const SizedBox(height: 24),

              // ── Feedback si rechazado ────────────────────────────────────
              if (d.estado == 'rechazado' && d.feedback != null) ...[
                _FeedbackCard(feedback: d.feedback!),
                const SizedBox(height: 20),
              ],

              // ── Galería de referencias ───────────────────────────────────
              briefAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (brief) {
                  final refs = brief?.referenciasUrls ?? [];
                  if (refs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SeccionLabel('REFERENCIAS'),
                      const SizedBox(height: 10),
                      _GaleriaHorizontal(urls: refs, isCeo: isCeo),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // ── Avances subidos ──────────────────────────────────────────
              avancesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (avances) {
                  if (avances.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SeccionLabel('AVANCES SUBIDOS'),
                      const SizedBox(height: 10),
                      _AvancesList(avances: avances, isCeo: isCeo),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // ── Brief ────────────────────────────────────────────────────
              const _SeccionLabel('BRIEF'),
              const SizedBox(height: 12),
              briefAsync.when(
                loading: () => _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (brief) => brief == null
                    ? Text('Sin brief disponible',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textTertiary))
                    : _BriefContent(brief: brief, disenio: d),
              ),
              const SizedBox(height: 24),

              // ── Acciones ─────────────────────────────────────────────────
              const _SeccionLabel('ACCIONES'),
              const SizedBox(height: 12),
              _AccionesSection(
                disenio: d,
                isCeo: isCeo,
                esMiDisenio: esMiDisenio,
                avances: avancesAsync.valueOrNull ?? [],
              ),
              const SizedBox(height: 24),

              // ── Producción (solo cuando aprobado) ────────────────────────
              if (d.estado == 'aprobado') ...[
                const _SeccionLabel('PRODUCCIÓN'),
                const SizedBox(height: 12),
                _SeccionProduccion(disenio: d, brief: brief),
                const SizedBox(height: 24),
              ],

              // ── Historial ────────────────────────────────────────────────
              const _SeccionLabel('HISTORIAL'),
              const SizedBox(height: 12),
              historialAsync.when(
                loading: () => _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => _HistorialTimeline(items: items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menú CEO (cancelar / eliminar) ──────────────────────────────────────────

class _CeoMenuButton extends ConsumerWidget {
  final Disenio disenio;
  const _CeoMenuButton({required this.disenio});

  String? get _siguienteEstado => CambiarEstadoNotifier.nextEstado(disenio.estado);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siguiente = _siguienteEstado;
    final puedeEliminar =
        disenio.estado == 'aprobado' || disenio.estado == 'rechazado' || disenio.estado == 'cancelado';
    final puedeCancelar = disenio.estado != 'cancelado' && disenio.estado != 'aprobado';

    return PopupMenuButton<String>(
      color: AppColors.surface2,
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        if (siguiente != null)
          PopupMenuItem(
            value: 'forzar',
            child: Row(children: [
              const Icon(Icons.fast_forward_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: 10),
              Text('Forzar → ${EstadoChip.labelForEstado(siguiente)}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.info)),
            ]),
          ),
        if (puedeCancelar)
          PopupMenuItem(
            value: 'cancelar',
            child: Row(children: [
              const Icon(Icons.cancel_outlined, size: 16, color: AppColors.warning),
              const SizedBox(width: 10),
              Text('Cancelar diseño',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.warning)),
            ]),
          ),
        if (puedeEliminar)
          PopupMenuItem(
            value: 'eliminar',
            child: Row(children: [
              const Icon(Icons.delete_forever_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Eliminar definitivamente',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
            ]),
          ),
      ],
      onSelected: (action) async {
        if (action == 'forzar' && siguiente != null) {
          await _confirmarForzar(context, ref, siguiente);
        } else if (action == 'cancelar') {
          await _confirmarCancelar(context, ref);
        } else if (action == 'eliminar') {
          await _confirmarEliminar(context, ref);
        }
      },
    );
  }

  Future<void> _confirmarForzar(
      BuildContext context, WidgetRef ref, String siguiente) async {
    final label = EstadoChip.labelForEstado(siguiente);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('¿Avanzar a $label?',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Avanzar a $label sin confirmación de la diseñadora?',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Se notificará a la diseñadora del cambio',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.info)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style:
                      GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirmar',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(cambiarEstadoProvider.notifier).forzar(disenio.id);
    if (context.mounted) context.pop();
  }

  Future<void> _confirmarCancelar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('¿Cancelar diseño?',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
            'Se notificará a la diseñadora. El diseño quedará en estado "Cancelado".',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sí, cancelar',
                  style: GoogleFonts.inter(
                      color: AppColors.warning, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(cancelarDisenioProvider.notifier).cancelar(disenio.id);
    if (context.mounted) context.pop();
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('¿Eliminar "${disenio.titulo}"?',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
        content: Text('Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar',
                  style: GoogleFonts.inter(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final elimino = await ref
        .read(eliminarDisenioProvider.notifier)
        .eliminar(disenio.id);
    if (elimino && context.mounted) context.pop();
  }
}

// ─── Sección Brief ────────────────────────────────────────────────────────────

class _BriefContent extends StatelessWidget {
  final dynamic brief;
  final Disenio disenio;
  const _BriefContent({required this.brief, required this.disenio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (disenio.dropNombre != null)
            _BriefRow(
              label: 'Drop',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(disenio.dropNombre!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ),
            )
          else
            _BriefRow(
              label: 'Drop',
              child: Text('Prenda suelta',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textTertiary)),
            ),

          // Fecha de idea
          _BriefRow(
            label: 'Fecha de idea',
            child: Text(
              _fmt(disenio.createdAt),
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),

          // Fecha límite
          if (brief.fechaLimite != null)
            _BriefRow(
              label: 'Fecha límite de entrega',
              child: Text(
                _fmt(brief.fechaLimite!),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),

          if (brief.descripcion != null)
            _BriefRow(
              label: 'Descripción',
              child: Text(brief.descripcion!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ),

          if ((brief.colores as List).isNotEmpty)
            _BriefRow(
              label: 'Colores',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (brief.colores as List<String>)
                    .map((c) => ColorChip(valor: c))
                    .toList(),
              ),
            ),

          if (brief.tipografia != null)
            _BriefRow(
              label: 'Tipografía',
              child: Text(brief.tipografia!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),

          if (brief.notasAdicionales != null)
            _BriefRow(
              label: 'Notas adicionales',
              child: Text(brief.notasAdicionales!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      DateFormat("d 'de' MMMM yyyy", 'es').format(d);
}

class _BriefRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _BriefRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ─── Acciones ─────────────────────────────────────────────────────────────────

class _AccionesSection extends ConsumerWidget {
  final Disenio disenio;
  final bool isCeo;
  final bool esMiDisenio;
  final List<DisenioAvance> avances;

  const _AccionesSection({
    required this.disenio,
    required this.isCeo,
    required this.esMiDisenio,
    this.avances = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cambiarState = ref.watch(cambiarEstadoProvider);
    final aprobarState = ref.watch(aprobarDisenioProvider);
    final rechazarState = ref.watch(rechazarDisenioProvider);
    final loading = cambiarState is AsyncLoading ||
        aprobarState is AsyncLoading ||
        rechazarState is AsyncLoading;

    if (disenio.estado == 'cancelado') {
      return _InfoCard(
          msg: 'Este diseño fue cancelado.', color: AppColors.textTertiary);
    }

    if (isCeo) {
      return _AccionesCeo(
          disenio: disenio, ref: ref, loading: loading, avances: avances);
    }
    if (esMiDisenio) {
      return _AccionesDisenadora(disenio: disenio, ref: ref, loading: loading);
    }
    return Text('Sin acciones para tu rol en este estado.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary));
  }
}

// ─── Acciones CEO ─────────────────────────────────────────────────────────────

class _AccionesCeo extends StatelessWidget {
  final Disenio disenio;
  final WidgetRef ref;
  final bool loading;
  final List<DisenioAvance> avances;
  const _AccionesCeo(
      {required this.disenio,
      required this.ref,
      required this.loading,
      this.avances = const []});

  @override
  Widget build(BuildContext context) {
    return switch (disenio.estado) {
      // BRIEF: CEO aprueba para iniciar o rechaza con feedback.
      'brief' => Column(
          children: [
            _BotonAccion(
              label: 'Aprobar brief → Iniciar proceso',
              icon: Icons.thumb_up_outlined,
              color: AppColors.warning,
              loading: loading,
              onTap: () async {
                final ok = await ref
                    .read(cambiarEstadoProvider.notifier)
                    .cambiar(disenio.id, 'proceso');
                if (ok && context.mounted) context.pop();
              },
            ),
            const SizedBox(height: 10),
            _BotonAccion(
              label: 'Rechazar brief',
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              loading: loading,
              onTap: () => _showRechazarDialog(context, ref,
                  titulo: 'Rechazar brief',
                  hint: 'Indica qué debe cambiar en el brief...'),
            ),
          ],
        ),

      // PROCESO: diseñadora está trabajando, CEO espera el boceto.
      'proceso' => const _InfoCard(
          msg: 'Esperando boceto / avance de la diseñadora.',
          color: AppColors.warning,
        ),

      // AVANCE: CEO revisa el boceto subido por la diseñadora.
      'avance' => Column(
          children: [
            _BotonAccion(
              label: 'Aprobar avance → Pedir diseño final',
              icon: Icons.thumb_up_outlined,
              color: AppColors.success,
              loading: loading,
              onTap: () async {
                final ok = await ref
                    .read(cambiarEstadoProvider.notifier)
                    .cambiar(disenio.id, 'revision');
                if (ok && context.mounted) context.pop();
              },
            ),
            const SizedBox(height: 10),
            _BotonAccion(
              label: 'Pedir cambios',
              icon: Icons.edit_note_rounded,
              color: AppColors.warning,
              loading: loading,
              onTap: () => _showRechazarDialog(context, ref),
            ),
          ],
        ),

      // REVISION: diseñadora sube el diseño final.
      // CEO espera hasta que haya avances nuevos, luego aprueba.
      'revision' => avances.isEmpty
          ? const _InfoCard(
              msg: 'Esperando diseño final de la diseñadora.',
              color: AppColors.info,
            )
          : Column(
              children: [
                _BotonAccion(
                  label: 'Aprobar diseño final',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  loading: loading,
                  onTap: () async {
                    final ok = await ref
                        .read(aprobarDisenioProvider.notifier)
                        .aprobar(disenio.id);
                    if (ok && context.mounted) context.pop();
                  },
                ),
                const SizedBox(height: 10),
                _BotonAccion(
                  label: 'Rechazar con feedback',
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  loading: loading,
                  onTap: () => _showRechazarDialog(context, ref),
                ),
              ],
            ),

      // RECHAZADO: CEO espera nueva versión de la diseñadora.
      'rechazado' => const _InfoCard(
          msg: 'Esperando nueva versión de la diseñadora.',
          color: AppColors.info,
        ),

      _ => const _InfoCard(msg: 'Diseño aprobado ✓', color: AppColors.success),
    };
  }

  void _showRechazarDialog(BuildContext context, WidgetRef ref,
      {String titulo = 'Rechazar con feedback',
      String hint = 'Describe qué debe mejorar...'}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _RechazarDialog(
        ctrl: ctrl,
        titulo: titulo,
        hint: hint,
        onConfirm: () async {
          final feedback = ctrl.text.trim();
          if (feedback.isEmpty) return;
          final ok = await ref
              .read(rechazarDisenioProvider.notifier)
              .rechazar(disenio.id, feedback);
          if (ok && context.mounted) {
            Navigator.pop(context);
            context.pop();
          }
        },
      ),
    );
  }
}

// ─── Acciones Diseñadora ──────────────────────────────────────────────────────

class _AccionesDisenadora extends StatelessWidget {
  final Disenio disenio;
  final WidgetRef ref;
  final bool loading;
  const _AccionesDisenadora(
      {required this.disenio, required this.ref, required this.loading});

  @override
  Widget build(BuildContext context) {
    return switch (disenio.estado) {
      // BRIEF: el brief fue enviado al CEO, diseñadora solo espera.
      // Solo el CEO puede aprobar e iniciar el proceso.
      'brief' => const _InfoCard(
          msg: 'Brief enviado al CEO. Esperando aprobación para iniciar el diseño.',
          color: AppColors.warning,
        ),

      // PROCESO: CEO aprobó el brief. Diseñadora puede subir avances.
      'proceso' => _BotonAccion(
          label: 'Subir avance',
          icon: Icons.upload_rounded,
          color: const Color(0xFF8B5CF6),
          loading: loading,
          onTap: () => _showSubirAvance(context, ref),
        ),

      // AVANCE: avance subido, CEO lo está revisando.
      'avance' => const _InfoCard(
          msg: 'Avance enviado. Esperando revisión y feedback del CEO.',
          color: Color(0xFF8B5CF6),
        ),

      // REVISION: CEO aprobó el boceto, diseñadora sube el diseño final.
      'revision' => _BotonAccion(
          label: 'Subir diseño final',
          icon: Icons.cloud_upload_rounded,
          color: AppColors.accent,
          loading: loading,
          onTap: () => _showSubirAvance(context, ref, esFinal: true),
        ),

      // RECHAZADO: CEO rechazó con feedback. Diseñadora sube nueva versión.
      'rechazado' => _BotonAccion(
          label: 'Subir nueva versión',
          icon: Icons.refresh_rounded,
          color: AppColors.info,
          loading: loading,
          onTap: () async {
            final ok = await ref
                .read(cambiarEstadoProvider.notifier)
                .cambiar(disenio.id, 'proceso', subeVersion: true);
            if (ok && context.mounted) context.pop();
          },
        ),

      // APROBADO: diseño aprobado, producción se encarga del resto.
      _ => const _InfoCard(
          msg: 'Diseño aprobado ✓ Pasa a producción.',
          color: AppColors.success,
        ),
    };
  }

  void _showSubirAvance(BuildContext context, WidgetRef ref,
      {bool esFinal = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubirAvanceSheet(
        disenioId: disenio.id,
        disenioTitulo: disenio.titulo,
        ref: ref,
        esFinal: esFinal,
      ),
    );
  }
}

// ─── Sheet: subir avance ──────────────────────────────────────────────────────

class _SubirAvanceSheet extends ConsumerStatefulWidget {
  final String disenioId;
  final String disenioTitulo;
  final WidgetRef ref;
  final bool esFinal;
  const _SubirAvanceSheet(
      {required this.disenioId,
      required this.disenioTitulo,
      required this.ref,
      this.esFinal = false});

  @override
  ConsumerState<_SubirAvanceSheet> createState() => _SubirAvanceSheetState();
}

class _SubirAvanceSheetState extends ConsumerState<_SubirAvanceSheet> {
  final _notaCtrl = TextEditingController();
  Uint8List? _bytes;
  String? _ext;

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImagen() async {
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _bytes = bytes;
        _ext = file.name.split('.').last.toLowerCase();
      });
    } catch (_) {}
  }

  Future<void> _subir() async {
    if (_bytes == null) return;
    final ok = await ref.read(subirAvanceProvider.notifier).subir(
          disenioId: widget.disenioId,
          disenioTitulo: widget.disenioTitulo,
          bytes: _bytes!,
          ext: _ext ?? 'jpg',
          nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
          esFinal: widget.esFinal,
        );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Avance subido',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(subirAvanceProvider) is AsyncLoading;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    widget.esFinal ? 'Subir versión final' : 'Subir avance',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Imagen
          GestureDetector(
            onTap: _pickImagen,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _bytes != null
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: _bytes != null
                  ? Image.memory(_bytes!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 32, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('Toca para seleccionar imagen del avance *',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textTertiary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Nota
          Text('Nota (opcional)',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _notaCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe qué incluye este avance...',
              hintStyle:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_bytes == null || isSaving) ? null : _subir,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                disabledBackgroundColor:
                    const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Subir avance',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avances list ─────────────────────────────────────────────────────────────

class _AvancesList extends StatelessWidget {
  final List<DisenioAvance> avances;
  final bool isCeo;
  const _AvancesList({required this.avances, this.isCeo = false});

  @override
  Widget build(BuildContext context) {
    final urls = avances.map((a) => a.imagenUrl).toList();
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: avances.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = avances[i];
          return GestureDetector(
            onTap: () => _ImageViewer.show(context, urls, i, canDownload: isCeo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: a.imagenUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 100, height: 100, color: AppColors.surface2),
                    errorWidget: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: AppColors.surface2,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM', 'es').format(a.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Galería horizontal ───────────────────────────────────────────────────────

class _GaleriaHorizontal extends StatelessWidget {
  final List<String> urls;
  final bool isCeo;
  const _GaleriaHorizontal({required this.urls, this.isCeo = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _ImageViewer.show(context, urls, i, canDownload: isCeo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: urls[i],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 120, height: 120, color: AppColors.surface2),
              errorWidget: (_, __, ___) => Container(
                width: 120,
                height: 120,
                color: AppColors.surface2,
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textTertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Historial timeline (datos reales de DB) ──────────────────────────────────

class _HistorialTimeline extends StatelessWidget {
  final List<DisenioHistorial> items;
  const _HistorialTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('Sin historial disponible',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textTertiary));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                        color: _colorForAccion(item.accion),
                        shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 32, color: AppColors.border),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.accion,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      if (item.descripcion != null)
                        Text(item.descripcion!,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4)),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (item.usuarioNombre != null) ...[
                          Text(item.usuarioNombre!,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                          Text(' · ',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textTertiary)),
                        ],
                        Text(timeago.format(item.createdAt, locale: 'es'),
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textTertiary)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _colorForAccion(String accion) {
    final a = accion.toLowerCase();
    if (a.contains('brief')) return const Color(0xFF3B82F6);
    if (a.contains('avance') || a.contains('versión')) return const Color(0xFF8B5CF6);
    if (a.contains('aprobado') || a.contains('inventario')) return AppColors.success;
    if (a.contains('rechazado')) return AppColors.error;
    if (a.contains('cancelado')) return AppColors.textTertiary;
    if (a.contains('revisión') || a.contains('revision')) return AppColors.accent;
    if (a.contains('manualmente')) return AppColors.info;
    return AppColors.textSecondary;
  }
}

// ─── Sección Producción (solo cuando aprobado) ────────────────────────────────

class _SeccionProduccion extends ConsumerWidget {
  final Disenio disenio;
  final Brief? brief;
  const _SeccionProduccion({required this.disenio, this.brief});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref
        .watch(productosDeDisenioProvider(disenio.id))
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final rol = ref.watch(currentUserProvider).valueOrNull?['rol'] as String? ?? '';
    final puedeGestionarInventario =
        rol == 'ceo' || rol == 'manager' || rol == 'produccion';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                size: 15, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Diseño aprobado · Listo para producción',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success)),
          ]),
          if (count > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                    'En inventario · $count talla${count == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ),
              if (puedeGestionarInventario) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push('/inventario'),
                  child: Text('Ver en inventario →',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ]),
          ],
          if (puedeGestionarInventario) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CrearProductoDesdeDisenioSheet(
                      disenio: disenio,
                      brief: brief,
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(productosDeDisenioProvider(disenio.id));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: Text(
                    count > 0 ? 'Agregar más tallas' : 'Crear en inventario',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets de soporte ───────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  final String text;
  const _SeccionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.8));
  }
}

class _FeedbackCard extends StatelessWidget {
  final String feedback;
  const _FeedbackCard({required this.feedback});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.feedback_outlined, size: 15, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Feedback del CEO',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          ]),
          const SizedBox(height: 8),
          Text(feedback,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.error, height: 1.5)),
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final int version;
  const _VersionBadge(this.version);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.surface3, borderRadius: BorderRadius.circular(6)),
      child: Text('v$version',
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _BotonAccion(
      {required this.label,
      required this.icon,
      required this.color,
      required this.loading,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label,
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String msg;
  final Color color;
  const _InfoCard({required this.msg, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: color, height: 1.4))),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent)),
    );
  }
}

class _RechazarDialog extends StatefulWidget {
  final TextEditingController ctrl;
  final VoidCallback onConfirm;
  final String titulo;
  final String hint;
  const _RechazarDialog({
    required this.ctrl,
    required this.onConfirm,
    this.titulo = 'Feedback / Rechazo',
    this.hint = 'Ej: Cambiar la paleta de colores...',
  });
  @override
  State<_RechazarDialog> createState() => _RechazarDialogState();
}

class _RechazarDialogState extends State<_RechazarDialog> {
  bool _hasText = false;
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(
        () => setState(() => _hasText = widget.ctrl.text.trim().isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.titulo,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Escribe el motivo o los cambios requeridos.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          TextField(
            controller: widget.ctrl,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textPlaceholder),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _hasText ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Confirmar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── Visor de imágenes fullscreen ─────────────────────────────────────────────

class _ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final bool canDownload;

  const _ImageViewer({
    required this.urls,
    this.initialIndex = 0,
    this.canDownload = false,
  });

  static void show(
    BuildContext context,
    List<String> urls,
    int index, {
    bool canDownload = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _ImageViewer(
        urls: urls,
        initialIndex: index,
        canDownload: canDownload,
      ),
    );
  }

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _download() {
    // Para web: abre la URL en nueva pestaña.
    // En mobile se puede integrar url_launcher si se añade la dependencia.
    final url = widget.urls[_current];
    // ignore: avoid_print
    if (kDebugMode) print('[ImageViewer] download: $url');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── PageView de imágenes ──────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Center(
              child: SizedBox(
                width: size.width * 0.88,
                height: size.height * 0.85,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Container(
                      color: AppColors.surface2,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surface2,
                      child: Icon(Icons.broken_image_outlined,
                          size: 48, color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Barra superior: contador + descargar + cerrar ─────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Contador (solo si hay más de 1)
                if (widget.urls.length > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_current + 1} / ${widget.urls.length}',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                const Spacer(),

                // Botón descargar (solo CEO)
                if (widget.canDownload)
                  GestureDetector(
                    onTap: _download,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text('Descargar',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                // Botón cerrar
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Indicadores de punto (múltiples imágenes) ─────────────────────
          if (widget.urls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

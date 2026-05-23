import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'guia_slide.dart';
import 'guias_provider.dart';

// --- Bottom sheet de guía con slides navegables -------------------------------
// Usa AnimatedSwitcher en lugar de PageView para evitar el conflicto de
// ScrollController en Flutter web (mouse_tracker.dart assertion).

class GuiaBottomSheet extends StatefulWidget {
  final List<GuiaSlide> slides;

  const GuiaBottomSheet({super.key, required this.slides});

  @override
  State<GuiaBottomSheet> createState() => _GuiaBottomSheetState();
}

class _GuiaBottomSheetState extends State<GuiaBottomSheet> {
  int _current = 0;

  void _siguiente() {
    if (!mounted) return;
    if (_current < widget.slides.length - 1) {
      setState(() => _current++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _saltar() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slides[_current];
    final isLast = _current == widget.slides.length - 1;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slide content · AnimatedSwitcher evita conflicto de scroll con web
          SizedBox(
            height: 260,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _buildSlide(slide),
            ),
          ),

          const SizedBox(height: 20),

          // Indicadores de progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Navegación
          Row(
            children: [
              if (!isLast)
                TextButton(
                  onPressed: _saltar,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: Text(
                    'Saltar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _siguiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: Text(
                    isLast
                        ? (slide.botonFinal ?? '¡Entendido!')
                        : 'Siguiente ?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  // Key en el widget raíz del slide para que AnimatedSwitcher lo detecte.
  // SingleChildScrollView permite que el texto largo no desborde el SizedBox.
  Widget _buildSlide(GuiaSlide slide) {
    return SingleChildScrollView(
      key: ValueKey(_current),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 16),
          Text(
            slide.titulo,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.texto,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}

// --- Lanzador automático ------------------------------------------------------
// Usa Future.delayed en lugar de addPostFrameCallback para garantizar que
// el framework esté en fase idle antes de abrir el BottomSheet (fix para
// mouse_tracker.dart:199:12 en Flutter web).

class OnboardingLauncher extends ConsumerStatefulWidget {
  final String modulo;
  final List<GuiaSlide> slides;

  const OnboardingLauncher({
    super.key,
    required this.modulo,
    required this.slides,
  });

  @override
  ConsumerState<OnboardingLauncher> createState() => _OnboardingLauncherState();
}

class _OnboardingLauncherState extends ConsumerState<OnboardingLauncher> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    // 600 ms: asegura que el árbol de widgets esté completamente estable
    // antes de abrir el BottomSheet, evitando el assertion de mouse_tracker
    // en Flutter web.
    Future.delayed(const Duration(milliseconds: 600), _tryShow);
  }

  Future<void> _tryShow() async {
    if (!mounted || _launched) return;
    _launched = true;
    try {
      final visto =
          await ref.read(guiaVistaProvider(widget.modulo).future);
      if (!visto && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true, // true en web evita el loop del mouse tracker
          builder: (_) => GuiaBottomSheet(slides: widget.slides),
        );
        if (!mounted) return;
        await marcarGuiaVista(widget.modulo);
        ref.invalidate(guiaVistaProvider(widget.modulo));
      }
    } catch (e) {
      if (kDebugMode) print('[OnboardingLauncher:${widget.modulo}] ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// --- Botón de ayuda ? para re-abrir la guía manualmente ----------------------

class GuiaHelpButton extends StatelessWidget {
  final List<GuiaSlide> slides;

  const GuiaHelpButton({super.key, required this.slides});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.help_outline_rounded,
        size: 20,
        color: AppColors.textTertiary,
      ),
      tooltip: 'Ver guía',
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      onPressed: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            enableDrag: true,
            builder: (_) => GuiaBottomSheet(slides: slides),
          );
        });
      },
    );
  }
}

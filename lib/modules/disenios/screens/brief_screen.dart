import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/briefs_provider.dart';
import '../widgets/brief_form.dart';

class BriefScreen extends ConsumerStatefulWidget {
  const BriefScreen({super.key});

  @override
  ConsumerState<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends ConsumerState<BriefScreen> {
  final _ctrl = BriefFormController();
  bool _puedeEnviar = false;

  @override
  void initState() {
    super.initState();
    _ctrl.tituloCtrl.addListener(_checkValidity);
    _ctrl.descripcionCtrl.addListener(_checkValidity);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _checkValidity() {
    final valid = _ctrl.isValid;
    if (valid != _puedeEnviar) {
      setState(() => _puedeEnviar = valid);
    }
  }

  Future<void> _enviar() async {
    if (!_ctrl.isValid) return;

    final ok = await ref.read(crearBriefProvider.notifier).crear(
          titulo: _ctrl.tituloCtrl.text,
          dropId: _ctrl.dropId, // null = Prenda suelta
          descripcion: _ctrl.descripcionCtrl.text,
          fechaLimite: _ctrl.fechaLimite!,
          colores: List.from(_ctrl.colores),
          tipografia: _ctrl.tipografiaCtrl.text.isEmpty
              ? null
              : _ctrl.tipografiaCtrl.text,
          notasAdicionales: _ctrl.notasCtrl.text.isEmpty
              ? null
              : _ctrl.notasCtrl.text,
          imagenes: List.from(_ctrl.imagenes),
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Brief enviado al CEO para revisión',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      // Navega siempre a Mis Diseños para que el nuevo brief aparezca en la lista.
      context.go('/disenios');
    } else {
      // Muestra el error al usuario en vez de quedarse en el formulario sin feedback.
      final errState = ref.read(crearBriefProvider);
      final msg = errState.maybeWhen(
        error: (e, _) {
          final s = e.toString();
          if (s.contains('42501') || s.contains('RLS') || s.contains('permission')) {
            return 'Sin permisos para guardar el brief. Contacta a un CEO.';
          }
          if (s.contains('violates') || s.contains('check')) {
            return 'Error de validación en la base de datos.';
          }
          return 'Error al guardar: $s';
        },
        orElse: () => 'No se pudo guardar el brief. Inténtalo de nuevo.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crearState = ref.watch(crearBriefProvider);
    final isLoading = crearState is AsyncLoading;

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
              context.go('/disenios');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo Brief',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _puedeEnviar ? 'LISTO PARA ENVIAR' : 'BORRADOR',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _puedeEnviar
                    ? AppColors.success
                    : AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _puedeEnviar && !isLoading ? _enviar : null,
              style: TextButton.styleFrom(
                backgroundColor: _puedeEnviar
                    ? AppColors.accent
                    : AppColors.surface2,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enviar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: BriefForm(
          controller: _ctrl,
          onChanged: _checkValidity,
        ),
      ),
    );
  }
}

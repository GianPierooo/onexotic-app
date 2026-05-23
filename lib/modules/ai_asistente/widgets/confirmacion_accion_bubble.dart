import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/ai_asistente_provider.dart';

class ConfirmacionAccionBubble extends StatelessWidget {
  final ConfirmacionPendiente pendiente;
  final bool isEjecutando;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const ConfirmacionAccionBubble({
    super.key,
    required this.pendiente,
    required this.isEjecutando,
    required this.onConfirmar,
    required this.onCancelar,
  });

  String get _accionTitulo => switch (pendiente.tool) {
        'crear_brief' => 'Voy a crear este brief',
        'crear_tarea' => 'Voy a crear esta tarea',
        'crear_evento' => 'Voy a crear este evento',
        'aprobar_disenio' => 'Voy a aprobar este diseño',
        'rechazar_disenio' => 'Voy a rechazar este diseño',
        'crear_drop' => 'Voy a crear este drop',
        'crear_bono' => 'Voy a asignar este bono',
        'anuncio_equipo' => 'Voy a enviar este anuncio al equipo',
        _ => 'Voy a ejecutar esta acción',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 52),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              size: 14,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  width: 0.75,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _accionTitulo,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      pendiente.resumen,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BotonSecundario(
                          label: 'Cancelar',
                          onTap: isEjecutando ? null : onCancelar,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BotonPrimario(
                          label: isEjecutando ? 'Creando…' : 'Confirmar',
                          isLoading: isEjecutando,
                          onTap: isEjecutando ? null : onConfirmar,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .moveY(begin: 6, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _BotonPrimario extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  const _BotonPrimario({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _BotonSecundario({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/mensaje_chat.dart';

/// Burbuja de mensaje estilo WhatsApp:
/// - Propios a la derecha, color accent (#FF4500), texto blanco.
/// - Recibidos a la izquierda, color surface2 (#1E1E1E o equivalente claro),
///   texto primary.
class MensajeBurbuja extends StatelessWidget {
  final MensajeChat mensaje;
  final bool esPropio;

  const MensajeBurbuja({
    super.key,
    required this.mensaje,
    required this.esPropio,
  });

  @override
  Widget build(BuildContext context) {
    final radio = esPropio
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    final bg = esPropio ? AppColors.accent : AppColors.surface2;
    final color =
        esPropio ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radio,
                border: esPropio
                    ? null
                    : Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mensaje.mensaje,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.35,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatearHora(mensaje.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: esPropio
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (esPropio) ...[
                        const SizedBox(width: 4),
                        Icon(
                          mensaje.leido
                              ? Icons.done_all_rounded
                              : Icons.check_rounded,
                          size: 13,
                          color: mensaje.leido
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearHora(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

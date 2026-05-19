import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ai_provider.dart';

class MensajeBubble extends StatelessWidget {
  final MensajeChat mensaje;
  const MensajeBubble({super.key, required this.mensaje});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final w = mensaje.esUsuario
        ? _UserBubble(mensaje: mensaje, time: _formatTime(mensaje.timestamp))
        : _AIBubble(mensaje: mensaje, time: _formatTime(mensaje.timestamp));
    return w
        .animate()
        .fadeIn(duration: 220.ms)
        .moveY(begin: 6, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _UserBubble extends StatelessWidget {
  final MensajeChat mensaje;
  final String time;
  const _UserBubble({required this.mensaje, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.22),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.38),
                width: 0.5,
              ),
              // Asimétrico: 20 20 4 20 (esquina pegada al hablante)
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              mensaje.texto,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              time,
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 10.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIBubble extends StatelessWidget {
  final MensajeChat mensaje;
  final String time;
  const _AIBubble({required this.mensaje, required this.time});

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
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                    // Asimétrico IA: 20 20 20 4
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    mensaje.texto,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    time,
                    style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

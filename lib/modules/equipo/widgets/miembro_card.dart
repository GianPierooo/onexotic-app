import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/equipo_provider.dart';
import 'asistencia_bar.dart';
import 'rol_badge.dart';

class MiembroCard extends StatelessWidget {
  final UsuarioConStats stats;
  final VoidCallback? onTap;
  final bool? isOnline;

  const MiembroCard({super.key, required this.stats, this.onTap, this.isOnline});

  static const _meses = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final u = stats.usuario;
    final isCurrentUser =
        Supabase.instance.client.auth.currentUser?.id == u.id;
    final rolColor = RolBadge.colorForRol(u.rol);
    final mes = _meses[DateTime.now().month - 1];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? AppColors.accent.withValues(alpha: 0.30)
                : AppColors.border,
            width: isCurrentUser ? 1 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar 48px con online indicator + pulse
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: rolColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: rolColor.withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                        child: u.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  u.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _initiales(u.nombre, rolColor),
                                ),
                              )
                            : _initiales(u.nombre, rolColor),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        // isOnline: dato real de Realtime Presence.
                        // Fallback: true si es el usuario actual (siempre online).
                        child: _OnlineDot(online: isOnline ?? isCurrentUser),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.nombre,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TÚ',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            RolBadge(rol: u.rol),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                u.horarioDisplay,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Container(height: 0.5, color: AppColors.border),
              const SizedBox(height: 12),
              AsistenciaBar(
                porcentaje: stats.asistenciaMensual,
                mes: mes,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initiales(String nombre, Color color) {
    final parts = nombre.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : nombre.isNotEmpty
            ? nombre[0]
            : '?';
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  final bool online;
  const _OnlineDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: online ? AppColors.success : AppColors.textTertiary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );

    if (!online) return base;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              duration: 1600.ms,
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.4, 1.4),
              curve: Curves.easeOut,
            )
            .fadeOut(duration: 1600.ms),
        base,
      ],
    );
  }
}

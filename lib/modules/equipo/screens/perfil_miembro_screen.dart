import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/equipo_provider.dart';
import '../widgets/asistencia_bar.dart';
import '../widgets/rol_badge.dart';

class PerfilMiembroScreen extends ConsumerWidget {
  final UsuarioConStats stats;

  const PerfilMiembroScreen({super.key, required this.stats});

  static const _meses = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = stats.usuario;
    final rolColor = RolBadge.colorForRol(u.rol);
    final mes = _meses[DateTime.now().month - 1];

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
              context.go('/equipo');
            }
          },
        ),
        title: Text(
          u.nombre,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar grande + info ──────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: rolColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: u.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(u.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _initiales(u.nombre, rolColor, 28)),
                          )
                        : _initiales(u.nombre, rolColor, 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u.nombre,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RolBadge(rol: u.rol),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Info de contacto ──────────────────────────────────────
            _Section('INFORMACIÓN'),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.email_outlined, label: u.email),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.schedule_outlined,
                label: u.horarioDisplay),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.circle,
              label: u.activo ? 'Activo' : 'Inactivo',
              color: u.activo ? AppColors.success : AppColors.textTertiary,
            ),

            const SizedBox(height: 24),

            // ── Asistencia ────────────────────────────────────────────
            _Section('ASISTENCIA ESTE MES'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stats.asistenciaMensual == 0
                            ? 'Sin datos'
                            : '${stats.asistenciaMensual.round()}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: _asistColor(stats.asistenciaMensual),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AsistenciaBar(
                    porcentaje: stats.asistenciaMensual,
                    mes: mes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _asistColor(double pct) {
    if (pct == 0) return AppColors.textTertiary;
    if (pct >= 90) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  Widget _initiales(String nombre, Color color, double fontSize) {
    final parts = nombre.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : nombre.isNotEmpty ? nombre[0] : '?';
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: color ?? AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

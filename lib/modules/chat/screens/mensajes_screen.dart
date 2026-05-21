import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../equipo/widgets/rol_badge.dart';
import '../providers/bandeja_provider.dart';

class MensajesScreen extends ConsumerWidget {
  const MensajesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandejaAsync = ref.watch(bandejaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text(
          'Mensajes',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: bandejaAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No se pudo cargar la bandeja\n$e',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const _EmptyEquipoState();
          }
          final conMensajes = lista.where((c) => c.tieneMensajes).toList();
          final sinMensajes = lista.where((c) => !c.tieneMensajes).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (conMensajes.isNotEmpty) ...[
                const _SectionLabel('CONVERSACIONES'),
                const SizedBox(height: 10),
                ...conMensajes.asMap().entries.map(
                      (e) => _ConversacionItem(
                        preview: e.value,
                        index: e.key,
                      ),
                    ),
              ],
              if (sinMensajes.isNotEmpty) ...[
                if (conMensajes.isNotEmpty) const SizedBox(height: 22),
                const _SectionLabel('NUEVO MENSAJE'),
                const SizedBox(height: 10),
                ...sinMensajes.asMap().entries.map(
                      (e) => _ConversacionItem(
                        preview: e.value,
                        index: conMensajes.length + e.key,
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

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

// ─── Item de la lista ───────────────────────────────────────────────────────

class _ConversacionItem extends StatelessWidget {
  final ConversacionPreview preview;
  final int index;

  const _ConversacionItem({required this.preview, required this.index});

  String _safeTimeago(DateTime dt) {
    try {
      return timeago.format(dt, locale: 'es');
    } catch (_) {
      try {
        return timeago.format(dt);
      } catch (_) {
        return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otro = preview.otro;
    final rolColor = RolBadge.colorForRol(otro.rol);
    final tieneSinLeer = preview.sinLeer > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tieneSinLeer ? AppColors.surface2 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tieneSinLeer
              ? AppColors.accent.withValues(alpha: 0.25)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: ListTile(
        onTap: () => context.push('/mensajes/chat', extra: otro),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: _Avatar(usuario: otro, rolColor: rolColor),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otro.nombre,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: tieneSinLeer ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (preview.ultimaFecha != null)
              Text(
                _safeTimeago(preview.ultimaFecha!),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: tieneSinLeer
                      ? AppColors.accent
                      : AppColors.textTertiary,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: preview.ultimoMensaje != null
              ? Row(
                  children: [
                    if (preview.ultimoFueMio)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          'Tú: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        preview.ultimoMensaje!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: tieneSinLeer
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: tieneSinLeer
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tieneSinLeer) ...[
                      const SizedBox(width: 8),
                      _UnreadBadge(count: preview.sinLeer),
                    ],
                  ],
                )
              : Text(
                  '${otro.email} · ${RolBadgeLabel.label(otro.rol)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 240.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOut,
        )
        .moveY(
          begin: 6,
          end: 0,
          duration: 260.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class RolBadgeLabel {
  static String label(String rol) => switch (rol) {
        'ceo'        => 'CEO',
        'manager'    => 'Manager',
        'disenadora' => 'Diseñadora',
        'rrhh'       => 'RRHH',
        'produccion' => 'Producción',
        _            => rol,
      };
}

class _Avatar extends StatelessWidget {
  final dynamic usuario;
  final Color rolColor;
  const _Avatar({required this.usuario, required this.rolColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: rolColor.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: rolColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: usuario.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                usuario.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iniciales(),
              ),
            )
          : _iniciales(),
    );
  }

  Widget _iniciales() {
    final parts = (usuario.nombre as String).trim().split(' ');
    final ini = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : (usuario.nombre as String).isNotEmpty
            ? usuario.nombre[0]
            : '?';
    return Center(
      child: Text(
        ini.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: rolColor,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _EmptyEquipoState extends StatelessWidget {
  const _EmptyEquipoState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              'No hay miembros activos en el equipo',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

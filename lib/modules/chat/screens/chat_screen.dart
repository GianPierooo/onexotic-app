import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../equipo/models/usuario.dart';
import '../../equipo/widgets/rol_badge.dart';
import '../models/mensaje_chat.dart';
import '../providers/chat_provider.dart';
import '../widgets/mensaje_burbuja.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Usuario otro;
  const ChatScreen({super.key, required this.otro});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Marca como leídos los mensajes del remitente al abrir el chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      marcarMensajesLeidos(widget.otro.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    HapticFeedback.selectionClick();
    final ok = await ref.read(enviarMensajeProvider.notifier).enviar(
          paraUserId: widget.otro.id,
          mensaje: texto,
        );
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _scrollAlFinal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    }
    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final yo = Supabase.instance.client.auth.currentUser?.id ?? '';
    final mensajesAsync = ref.watch(mensajesChatProvider(widget.otro.id));
    final rolColor = RolBadge.colorForRol(widget.otro.rol);

    // Cada vez que llegan mensajes nuevos, los marcamos leídos si son entrantes.
    ref.listen(mensajesChatProvider(widget.otro.id), (_, next) {
      next.whenData((lista) {
        final hayNuevos = lista.any(
            (m) => m.deUserId == widget.otro.id && !m.leido);
        if (hayNuevos) marcarMensajesLeidos(widget.otro.id);
        _scrollAlFinal();
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/equipo'),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _Avatar(usuario: widget.otro, rolColor: rolColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otro.nombre,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Usuario.labelRol(widget.otro.rol),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: mensajesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.error),
                ),
              ),
              data: (mensajes) {
                if (mensajes.isEmpty) {
                  return _EmptyState(nombre: widget.otro.nombre);
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: mensajes.length,
                  itemBuilder: (_, i) {
                    final m = mensajes[i];
                    final prev = i > 0 ? mensajes[i - 1] : null;
                    final mostrarFecha = _debeMostrarSeparadorFecha(prev, m);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (mostrarFecha) _SeparadorFecha(fecha: m.createdAt),
                        MensajeBurbuja(
                          mensaje: m,
                          esPropio: m.esPropio(yo),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            enviando: _enviando,
            onEnviar: _enviar,
          ),
        ],
      ),
    );
  }

  bool _debeMostrarSeparadorFecha(MensajeChat? prev, MensajeChat actual) {
    if (prev == null) return true;
    final a = prev.createdAt;
    final b = actual.createdAt;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

// ─── Avatar pequeño del header ───────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Usuario usuario;
  final Color rolColor;
  const _Avatar({required this.usuario, required this.rolColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
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
    final parts = usuario.nombre.trim().split(' ');
    final ini = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : usuario.nombre.isNotEmpty
            ? usuario.nombre[0]
            : '?';
    return Center(
      child: Text(
        ini.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: rolColor,
        ),
      ),
    );
  }
}

// ─── Separador de fecha entre días ──────────────────────────────────────────

class _SeparadorFecha extends StatelessWidget {
  final DateTime fecha;
  const _SeparadorFecha({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatear(fecha),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatear(DateTime d) {
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    final f = DateTime(d.year, d.month, d.day);
    final diff = h.difference(f).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    if (diff < 7) return dias[d.weekday - 1];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String nombre;
  const _EmptyState({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin mensajes con $nombre',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Envía el primer mensaje',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar inferior ─────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enviando;
  final VoidCallback onEnviar;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enviando,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: 'Mensaje',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPlaceholder,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onEnviar(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: enviando ? null : onEnviar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enviando
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: enviando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

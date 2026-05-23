import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/ai_asistente_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/confirmacion_accion_bubble.dart';
import '../widgets/input_chat.dart' show InputChat, PickedImage;
import '../widgets/mensaje_bubble.dart';
import '../widgets/sugerencias_chips.dart';
import '../widgets/typing_indicator.dart';

/// Modo de operación de la pantalla IA.
enum AiModo { chat, asistente }

final aiModoProvider = StateProvider<AiModo>((_) => AiModo.chat);

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // mounted evita que un callback agendado se ejecute después de dispose
      // (escenarios: usuario sale de /ai mientras la IA aún responde).
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar(String texto) async {
    if (texto.trim().isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    final modo = ref.read(aiModoProvider);
    if (modo == AiModo.asistente) {
      await ref.read(aiAsistenteProvider.notifier).enviar(texto);
    } else {
      await ref.read(aiChatProvider.notifier).enviar(texto);
    }
    _scrollToBottom();
  }

  Future<void> _enviarConImagenes(String texto, List<PickedImage> imgs) async {
    if (texto.trim().isEmpty && imgs.isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    final adjuntas = imgs
        .map((i) => ImagenAdjunta(bytes: i.bytes, ext: i.ext, nombre: i.nombre))
        .toList();
    await ref
        .read(aiAsistenteProvider.notifier)
        .enviar(texto, imagenes: adjuntas);
    _scrollToBottom();
  }

  Future<void> _confirmarLimpiar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Limpiar conversación',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Confirmas que quieres limpiar el historial?',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Limpiar',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      final modo = ref.read(aiModoProvider);
      if (modo == AiModo.asistente) {
        ref.read(aiAsistenteProvider.notifier).limpiar();
      } else {
        ref.read(aiChatProvider.notifier).limpiar();
      }
    }
  }

  String _formatHora(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    final hora12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hora12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(aiModoProvider);
    final userAsync = ref.watch(currentUserProvider);
    final rolDinamico = userAsync.valueOrNull?['rol'];
    final rol = rolDinamico is String ? rolDinamico : 'ceo';
    final esCeo = rol == 'ceo' || rol == 'manager';

    // Si el rol cambia y el modo asistente ya no aplica, lo bajamos a chat
    // vía ref.listen — NO desde build() para evitar agendar setState en cada
    // rebuild (potencial loop si la condición persistía entre frames).
    ref.listen(currentUserProvider, (prev, next) {
      final nextRol = next.valueOrNull?['rol'];
      final nextEsCeo = nextRol == 'ceo' || nextRol == 'manager';
      if (!nextEsCeo && ref.read(aiModoProvider) == AiModo.asistente) {
        ref.read(aiModoProvider.notifier).state = AiModo.chat;
      }
    });

    // Listener para auto-scroll al entrar mensajes en cualquier modo.
    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if ((prev?.mensajes.length ?? 0) != next.mensajes.length) {
        _scrollToBottom();
      }
    });
    ref.listen<AiAsistenteState>(aiAsistenteProvider, (prev, next) {
      if ((prev?.mensajes.length ?? 0) != next.mensajes.length) {
        _scrollToBottom();
      }
    });

    final body = modo == AiModo.asistente
        ? _AsistenteBody(
            scrollController: _scrollController,
            formatHora: _formatHora,
          )
        : _ChatBody(
            scrollController: _scrollController,
            formatHora: _formatHora,
            rol: rol,
            onSugerencia: _enviar,
          );

    final isTyping = modo == AiModo.asistente
        ? ref.watch(aiAsistenteProvider.select((s) => s.isTyping || s.isEjecutando))
        : ref.watch(aiChatProvider.select((s) => s.isTyping));

    final isSubiendo = modo == AiModo.asistente
        ? ref.watch(aiAsistenteProvider.select((s) => s.isSubiendo))
        : false;

    final hasMessages = modo == AiModo.asistente
        ? ref.watch(aiAsistenteProvider.select((s) => s.mensajes.isNotEmpty))
        : ref.watch(aiChatProvider.select((s) => s.mensajes.isNotEmpty));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AppBarAI(
        modo: modo,
        esCeo: esCeo,
        hasMessages: hasMessages,
        onLimpiar: _confirmarLimpiar,
        onGuia: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const GuiaBottomSheet(slides: GuiasContent.ia),
            );
          });
        },
        onCambiarModo: (m) =>
            ref.read(aiModoProvider.notifier).state = m,
      ),
      body: Stack(
        children: [
          const OnboardingLauncher(
            modulo: 'ia',
            slides: GuiasContent.ia,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: body),
                if (modo == AiModo.chat)
                  Consumer(builder: (context, ref, _) {
                    final err = ref.watch(
                        aiChatProvider.select((s) => s.error));
                    if (err == null) return const SizedBox.shrink();
                    return _ErrorBanner(mensaje: err);
                  }),
                if (modo == AiModo.asistente)
                  Consumer(builder: (context, ref, _) {
                    final err = ref.watch(
                        aiAsistenteProvider.select((s) => s.error));
                    if (err == null) return const SizedBox.shrink();
                    return _ErrorBanner(mensaje: err);
                  }),
                if (modo == AiModo.chat)
                  SugerenciasChips(rol: rol, onTap: _enviar),
                InputChat(
                  controller: _textController,
                  focusNode: _focusNode,
                  isLoading: isTyping,
                  isSubiendo: isSubiendo,
                  onSend: _enviar,
                  // Solo en modo Asistente se permite adjuntar imágenes.
                  onSendConImagenes:
                      modo == AiModo.asistente ? _enviarConImagenes : null,
                  hint: modo == AiModo.asistente
                      ? 'Dile qué quieres crear…'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Body chat (modo informativo original) ────────────────────────────────────

class _ChatBody extends ConsumerWidget {
  final ScrollController scrollController;
  final String Function(DateTime) formatHora;
  final String rol;
  final Future<void> Function(String) onSugerencia;

  const _ChatBody({
    required this.scrollController,
    required this.formatHora,
    required this.rol,
    required this.onSugerencia,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(aiChatProvider);

    if (chatState.mensajes.isEmpty && !chatState.isTyping) {
      return _EmptyState(
        hora: formatHora(DateTime.now()),
        titulo: 'OnExotic AI',
        subtitulo: 'Pregúntame cualquier cosa sobre OnExotic',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: chatState.mensajes.length + (chatState.isTyping ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DateSeparator(hora: formatHora(DateTime.now()));
        }
        final msgIndex = index - 1;
        if (chatState.isTyping && msgIndex == chatState.mensajes.length) {
          return const TypingIndicator();
        }
        // Usamos el id del mensaje como key estable → flutter_animate adentro
        // del MensajeBubble solo dispara al insertarse, no en cada rebuild.
        // Si volvemos a envolver con .animate() aquí se acumulan animaciones
        // y termina en CONTEXT_LOST_WEBGL en Flutter web.
        final m = chatState.mensajes[msgIndex];
        return MensajeBubble(key: ValueKey(m.id), mensaje: m);
      },
    );
  }
}

// ─── Body asistente (modo con acciones) ───────────────────────────────────────

class _AsistenteBody extends ConsumerWidget {
  final ScrollController scrollController;
  final String Function(DateTime) formatHora;

  const _AsistenteBody({
    required this.scrollController,
    required this.formatHora,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(aiAsistenteProvider);

    if (s.mensajes.isEmpty && !s.isTyping) {
      return _EmptyState(
        hora: formatHora(DateTime.now()),
        titulo: 'Modo Asistente',
        subtitulo:
            'Dime qué hacer y lo ejecuto: crear tarea, evento o brief.',
        icono: Icons.auto_fix_high_rounded,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: s.mensajes.length + (s.isTyping ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DateSeparator(hora: formatHora(DateTime.now()));
        }
        final msgIndex = index - 1;
        if (s.isTyping && msgIndex == s.mensajes.length) {
          return const TypingIndicator();
        }
        final m = s.mensajes[msgIndex];
        // Burbuja especial: confirmación de acción pendiente.
        if (m.texto == '__pendiente_confirmacion__' &&
            s.pendiente?.mensajeId == m.id) {
          return ConfirmacionAccionBubble(
            key: ValueKey('conf_${m.id}'),
            pendiente: s.pendiente!,
            isEjecutando: s.isEjecutando,
            onConfirmar: () =>
                ref.read(aiAsistenteProvider.notifier).confirmar(),
            onCancelar: () =>
                ref.read(aiAsistenteProvider.notifier).cancelar(),
          );
        }
        return MensajeBubble(key: ValueKey(m.id), mensaje: m);
      },
    );
  }
}

// ─── Banner de error inline ───────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar personalizado con toggle Chat/Asistente ───────────────────────────

class _AppBarAI extends StatelessWidget implements PreferredSizeWidget {
  final AiModo modo;
  final bool esCeo;
  final bool hasMessages;
  final VoidCallback onLimpiar;
  final VoidCallback onGuia;
  final ValueChanged<AiModo> onCambiarModo;

  const _AppBarAI({
    required this.modo,
    required this.esCeo,
    required this.hasMessages,
    required this.onLimpiar,
    required this.onGuia,
    required this.onCambiarModo,
  });

  // AppBar + (toggle si CEO) + divisor 1px
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 1 + (esCeo ? 50 : 0));

  @override
  Widget build(BuildContext context) {
    final esAsistente = modo == AiModo.asistente;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      esAsistente
                          ? Icons.auto_fix_high_rounded
                          : Icons.smart_toy_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                  ),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        esAsistente ? 'OnExotic Asistente' : 'OnExotic AI',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          esAsistente ? 'ACCIONES' : 'BETA',
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    esAsistente
                        ? 'Ejecuta acciones por ti'
                        : 'Asistente interno · activo',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: onGuia,
              icon: Icon(
                Icons.help_outline_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              tooltip: 'Ver guía',
            ),
            if (hasMessages)
              IconButton(
                onPressed: onLimpiar,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                tooltip: 'Limpiar conversación',
              ),
            const SizedBox(width: 4),
          ],
        ),
        if (esCeo)
          _ModoToggle(modo: modo, onCambiar: onCambiarModo),
        Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _ModoToggle extends StatelessWidget {
  final AiModo modo;
  final ValueChanged<AiModo> onCambiar;
  const _ModoToggle({required this.modo, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentBtn(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                activo: modo == AiModo.chat,
                onTap: () => onCambiar(AiModo.chat),
              ),
            ),
            Expanded(
              child: _SegmentBtn(
                label: 'Asistente',
                icon: Icons.auto_fix_high_rounded,
                activo: modo == AiModo.asistente,
                onTap: () => onCambiar(AiModo.asistente),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool activo;
  final VoidCallback onTap;
  const _SegmentBtn({
    required this.label,
    required this.icon,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: activo ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: activo ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                color: activo ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Separador de fecha ────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String hora;
  const _DateSeparator({required this.hora});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'HOY · $hora',
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String hora;
  final String titulo;
  final String subtitulo;
  final IconData icono;
  const _EmptyState({
    required this.hora,
    required this.titulo,
    required this.subtitulo,
    this.icono = Icons.smart_toy_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icono,
              size: 32,
              color: AppColors.accent,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.85, 0.85), duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
          ),
          const SizedBox(height: 6),
          Text(
            'HOY · $hora',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

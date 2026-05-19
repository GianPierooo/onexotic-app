import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/onboarding/guia_bottom_sheet.dart';
import '../../../shared/onboarding/guias_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/input_chat.dart';
import '../widgets/mensaje_bubble.dart';
import '../widgets/sugerencias_chips.dart';
import '../widgets/typing_indicator.dart';

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
    await ref.read(aiChatProvider.notifier).enviar(texto);
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
      ref.read(aiChatProvider.notifier).limpiar();
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
    final chatState = ref.watch(aiChatProvider);
    final userAsync = ref.watch(currentUserProvider);
    final rol = userAsync.valueOrNull?['rol'] ?? 'ceo';

    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if ((prev?.mensajes.length ?? 0) != next.mensajes.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AppBarAI(
        hasMessages: chatState.mensajes.isNotEmpty,
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
            // ── Área de chat ────────────────────────────────────────────────
            Expanded(
              child: chatState.mensajes.isEmpty && !chatState.isTyping
                  ? _EmptyState(hora: _formatHora(DateTime.now()))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: chatState.mensajes.length +
                          (chatState.isTyping ? 1 : 0) +
                          1, // +1 separador de fecha
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _DateSeparator(
                              hora: _formatHora(DateTime.now()));
                        }
                        final msgIndex = index - 1;
                        if (chatState.isTyping &&
                            msgIndex == chatState.mensajes.length) {
                          return const TypingIndicator();
                        }
                        return MensajeBubble(
                          mensaje: chatState.mensajes[msgIndex],
                        )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              duration: 200.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
            ),
            // ── Error banner ─────────────────────────────────────────────────
            if (chatState.error != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: GoogleFonts.inter(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Sugerencias ──────────────────────────────────────────────────
            SugerenciasChips(rol: rol, onTap: _enviar),
            // ── Input ────────────────────────────────────────────────────────
            InputChat(
              controller: _textController,
              focusNode: _focusNode,
              isLoading: chatState.isTyping,
              onSend: _enviar,
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

// ─── AppBar personalizado ──────────────────────────────────────────────────────

class _AppBarAI extends StatelessWidget implements PreferredSizeWidget {
  final bool hasMessages;
  final VoidCallback onLimpiar;
  final VoidCallback onGuia;
  const _AppBarAI({
    required this.hasMessages,
    required this.onLimpiar,
    required this.onGuia,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(
                      Icons.smart_toy_outlined,
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
                        'OnExotic AI',
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
                          'BETA',
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
                    'Asistente interno · activo',
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
        Container(height: 1, color: AppColors.border),
      ],
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
  const _EmptyState({required this.hora});

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
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 32,
              color: AppColors.accent,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.85, 0.85), duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            'OnExotic AI',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 6),
          Text(
            'Pregúntame cualquier cosa sobre OnExotic',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
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

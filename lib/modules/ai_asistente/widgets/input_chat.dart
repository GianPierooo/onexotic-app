import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class InputChat extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final void Function(String) onSend;

  const InputChat({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<InputChat> createState() => _InputChatState();
}

class _InputChatState extends State<InputChat> {
  bool _hasText = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateHasText);
    widget.focusNode.addListener(_updateFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasText);
    widget.focusNode.removeListener(_updateFocus);
    super.dispose();
  }

  void _updateHasText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _updateFocus() {
    if (widget.focusNode.hasFocus != _focused) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !widget.isLoading && _hasText;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.of(context).padding.bottom * 0.3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(maxHeight: 132),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                border: Border.all(
                  color: _focused
                      ? AppColors.accent
                      : AppColors.border,
                  width: _focused ? 1 : 0.5,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.onSend,
                maxLines: null,
                cursorColor: AppColors.accent,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: 'Pregunta algo...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: canSend
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onSend(widget.controller.text);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.isLoading
                    ? AppColors.surface3
                    : canSend
                        ? AppColors.accent
                        : AppColors.accent.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: widget.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
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

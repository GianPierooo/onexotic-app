import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ai_context_builder.dart';

class SugerenciasChips extends StatelessWidget {
  final String rol;
  final void Function(String) onTap;
  const SugerenciasChips({super.key, required this.rol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sugerencias = AiContextBuilder.sugerenciasPorRol(rol);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sugerencias
            .map((s) => _SugerenciaChip(texto: s, onTap: () => onTap(s)))
            .toList(),
      ),
    );
  }
}

class _SugerenciaChip extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _SugerenciaChip({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
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

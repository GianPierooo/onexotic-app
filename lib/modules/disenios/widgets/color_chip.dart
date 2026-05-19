import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

// ─── Mapa de colores predefinidos ─────────────────────────────────────────────

const Map<String, Color> predefinedColorMap = {
  'Negro':   Color(0xFF1A1A1A),
  'Blanco':  Color(0xFFF0F0F0),
  'Gris':    Color(0xFF888888),
  'Crema':   Color(0xFFFFF0D0),
  'Beige':   Color(0xFFD4B896),
  'Marrón':  Color(0xFF6B3A2A),
  'Rojo':    Color(0xFFE53935),
  'Naranja': Color(0xFFF4511E),
  'Amarillo':Color(0xFFFBC02D),
  'Verde':   Color(0xFF43A047),
  'Azul':    Color(0xFF1E88E5),
  'Morado':  Color(0xFF8E24AA),
  'Rosa':    Color(0xFFE91E63),
};

// ─── Chip de color (nombre) ───────────────────────────────────────────────────

class ColorChip extends StatelessWidget {
  final String valor;   // Nombre del color: "Negro", "Azul media noche", etc.
  final VoidCallback? onRemove;

  const ColorChip({super.key, required this.valor, this.onRemove});

  Color get _circleColor =>
      predefinedColorMap[valor] ?? const Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Paleta predefinida ───────────────────────────────────────────────────────

class ColorPaletteSelector extends StatelessWidget {
  final List<String> seleccionados;
  final int maxColores;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const ColorPaletteSelector({
    super.key,
    required this.seleccionados,
    required this.maxColores,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final disponibles = predefinedColorMap.keys
        .where((n) => !seleccionados.contains(n))
        .toList();
    final lleno = seleccionados.length >= maxColores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips seleccionados
        if (seleccionados.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seleccionados
                .map((c) => ColorChip(
                      valor: c,
                      onRemove: () => onRemove(c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Paleta base
        if (disponibles.isNotEmpty && !lleno) ...[
          Text(
            'Colores base',
            style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: disponibles
                .map((nombre) => _PaletteButton(
                      nombre: nombre,
                      color: predefinedColorMap[nombre]!,
                      onTap: () => onAdd(nombre),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],

        // Botón personalizado
        if (!lleno)
          AgregarColorPersonalizadoButton(
            onColorAdded: (nombre) => onAdd(nombre),
          ),

        if (lleno)
          Text(
            'Máximo $maxColores colores',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

class _PaletteButton extends StatelessWidget {
  final String nombre;
  final Color color;
  final VoidCallback onTap;
  const _PaletteButton(
      {required this.nombre, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.borderHover, width: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              nombre,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón personalizado ──────────────────────────────────────────────────────

class AgregarColorPersonalizadoButton extends StatelessWidget {
  final ValueChanged<String> onColorAdded;
  const AgregarColorPersonalizadoButton({super.key, required this.onColorAdded});

  void _showDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Color personalizado',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ej: Azul media noche, Verde oliva...',
            hintStyle:
                GoogleFonts.inter(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) onColorAdded(val);
              Navigator.pop(ctx);
            },
            child: Text('Agregar',
                style: GoogleFonts.inter(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('Color personalizado',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

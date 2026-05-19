import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/usuario.dart';

class RolBadge extends StatelessWidget {
  final String rol;
  final bool small;

  const RolBadge({super.key, required this.rol, this.small = false});

  static Color colorForRol(String rol) => switch (rol) {
        'ceo'        => const Color(0xFFF59E0B),
        'manager'    => const Color(0xFFF97316),
        'disenadora' => const Color(0xFFA78BFA),
        'rrhh'       => const Color(0xFF3B82F6),
        'produccion' => const Color(0xFF22C55E),
        _            => const Color(0xFF888888),
      };

  @override
  Widget build(BuildContext context) {
    final color = colorForRol(rol);
    final fontSize = small ? 9.0 : 10.0;
    final hPad = small ? 5.0 : 7.0;
    final vPad = small ? 2.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        Usuario.labelRol(rol),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

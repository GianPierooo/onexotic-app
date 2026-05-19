import 'package:flutter/material.dart';

/// Paleta OnExotic · soporta tema oscuro y claro.
///
/// Mecanismo: el `OnExoticApp` actualiza [AppColors.brightness] antes de
/// construir el `MaterialApp` según el `themeMode` actual del usuario.
/// Los getters dinámicos resuelven el color correcto en cada rebuild.
///
/// IMPORTANTE: los getters NO son `const`. Si encuentras `const Container(
/// color: AppColors.background)` debes quitar el `const` exterior.
/// Los colores de marca (accent) y semánticos (success/warning/error/info)
/// Sí siguen siendo `const` porque son iguales en ambos temas.
class AppColors {
  AppColors._();

  // --- Brightness global (mutable) --------------------------------------------
  /// Brightness actual de la paleta. Se actualiza desde `OnExoticApp` cada vez
  /// que cambia el `themeMode`. Si nunca se cambia, asume `dark` por defecto.
  static Brightness brightness = Brightness.dark;
  static bool get _isDark => brightness == Brightness.dark;

  // --- PALETA DARK (constantes privadas) --------------------------------------
  static const _darkBackground       = Color(0xFF0A0A0A);
  static const _darkBackgroundDeep   = Color(0xFF050505);
  static const _darkSurface          = Color(0xFF141414);
  static const _darkSurface2         = Color(0xFF1A1A1A);
  static const _darkSurface3         = Color(0xFF1E1E1E);
  static const _darkSurface4         = Color(0xFF252525);
  static const _darkNavBackground    = Color(0xFF0D0D0D);
  static const _darkBorder           = Color(0xFF2A2A2A);
  static const _darkBorderSubtle     = Color(0xFF1E1E1E);
  static const _darkBorderHover      = Color(0xFF3A3A3A);
  static const _darkTextPrimary      = Color(0xFFFFFFFF);
  static const _darkTextSecondary    = Color(0xFF888888);
  static const _darkTextTertiary     = Color(0xFF555555);
  static const _darkTextPlaceholder  = Color(0xFF444444);
  static const _darkTextLabel        = Color(0xFF666666);

  // --- PALETA LIGHT (constantes privadas) -------------------------------------
  static const _lightBackground      = Color(0xFFF5F5F5);
  static const _lightBackgroundDeep  = Color(0xFFEDEDED);
  static const _lightSurface         = Color(0xFFFFFFFF);
  static const _lightSurface2        = Color(0xFFEFEFEF);
  static const _lightSurface3        = Color(0xFFE9E9E9);
  static const _lightSurface4        = Color(0xFFE0E0E0);
  static const _lightNavBackground   = Color(0xFFFFFFFF);
  static const _lightBorder          = Color(0xFFE0E0E0);
  static const _lightBorderSubtle    = Color(0xFFEDEDED);
  static const _lightBorderHover     = Color(0xFFCCCCCC);
  static const _lightTextPrimary     = Color(0xFF0A0A0A);
  static const _lightTextSecondary   = Color(0xFF555555);
  static const _lightTextTertiary    = Color(0xFF888888);
  static const _lightTextPlaceholder = Color(0xFFAAAAAA);
  static const _lightTextLabel       = Color(0xFF777777);

  // --- Fondos (getters dinámicos) ---------------------------------------------
  static Color get background     => _isDark ? _darkBackground     : _lightBackground;
  static Color get backgroundDeep => _isDark ? _darkBackgroundDeep : _lightBackgroundDeep;
  static Color get surface        => _isDark ? _darkSurface        : _lightSurface;
  static Color get surface2       => _isDark ? _darkSurface2       : _lightSurface2;
  static Color get surface3       => _isDark ? _darkSurface3       : _lightSurface3;
  static Color get surface4       => _isDark ? _darkSurface4       : _lightSurface4;
  static Color get navBackground  => _isDark ? _darkNavBackground  : _lightNavBackground;

  // --- Bordes -----------------------------------------------------------------
  static Color get border       => _isDark ? _darkBorder       : _lightBorder;
  static Color get borderSubtle => _isDark ? _darkBorderSubtle : _lightBorderSubtle;
  static Color get borderHover  => _isDark ? _darkBorderHover  : _lightBorderHover;

  // --- Textos -----------------------------------------------------------------
  static Color get textPrimary     => _isDark ? _darkTextPrimary     : _lightTextPrimary;
  static Color get textSecondary   => _isDark ? _darkTextSecondary   : _lightTextSecondary;
  static Color get textTertiary    => _isDark ? _darkTextTertiary    : _lightTextTertiary;
  static Color get textPlaceholder => _isDark ? _darkTextPlaceholder : _lightTextPlaceholder;
  static Color get textLabel       => _isDark ? _darkTextLabel       : _lightTextLabel;

  // --- Marca OnExotic (iguales en ambos temas · siguen siendo const) ----------
  static const accent       = Color(0xFFFF4500);
  static const accentHover  = Color(0xFFFF5A1F);
  static const accentDim    = Color(0x26FF4500); // 15% opacity
  static const accentSubtle = Color(0x1FFF4500); // 12% opacity
  static const accentGlow   = Color(0x40FF4500); // 25% opacity

  // --- Semánticos (iguales en ambos temas) ------------------------------------
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);

  // --- Áreas de tareas (iguales en ambos temas) -------------------------------
  static const areaTech       = Color(0xFF3B82F6);
  static const areaDisenio    = Color(0xFFA78BFA);
  static const areaMarketing  = Color(0xFFF97316);
  static const areaProduccion = Color(0xFF22C55E);
  static const areaRRHH       = Color(0xFF38BDF8);
  static const areaLegal      = Color(0xFFEF4444);

  /// Devuelve [color] con la opacidad alpha (0..1). Usar para fondos de badges.
  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}

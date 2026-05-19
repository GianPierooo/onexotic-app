import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Theme OnExotic · minimal premium, soporta dark y light.
///
/// Specs:
/// - Radius: 8 (chicos), 12 (inputs/botones), 16 (cards/sheets).
/// - Borders: 0.5px en cards / 1px en focus.
/// - Sin sombras · sólo color + borde.
/// - Inputs height 52, padding horizontal 16.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double borderHairline = 0.5;

  // ----------------------------------------------------------------------------
  // DARK THEME
  // ----------------------------------------------------------------------------
  static const _darkBg           = Color(0xFF0A0A0A);
  static const _darkSurface      = Color(0xFF141414);
  static const _darkSurface2     = Color(0xFF1A1A1A);
  static const _darkSurface3     = Color(0xFF1E1E1E);
  static const _darkBorder       = Color(0xFF2A2A2A);
  static const _darkTextPrimary  = Color(0xFFFFFFFF);
  static const _darkTextSecond   = Color(0xFF888888);
  static const _darkTextTertiary = Color(0xFF555555);
  static const _darkTextLabel    = Color(0xFF666666);
  static const _darkNavBg        = Color(0xFF0D0D0D);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _darkBg,
        canvasColor: _darkBg,
        colorScheme: const ColorScheme.dark(
          surface: _darkSurface,
          surfaceContainerHighest: _darkSurface3,
          primary: AppColors.accent,
          onPrimary: Colors.white,
          onSurface: _darkTextPrimary,
          onSurfaceVariant: _darkTextSecond,
          secondary: AppColors.accent,
          error: AppColors.error,
          outline: _darkBorder,
        ),
        textTheme: AppTypography.textTheme.apply(
          bodyColor: _darkTextPrimary,
          displayColor: _darkTextPrimary,
        ),
        cardTheme: const CardThemeData(
          color: _darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
            side: BorderSide(color: _darkBorder, width: borderHairline),
          ),
        ),
        dividerColor: _darkBorder,
        dividerTheme: const DividerThemeData(
          color: _darkBorder,
          thickness: borderHairline,
          space: borderHairline,
        ),
        iconTheme: const IconThemeData(color: _darkTextSecond, size: 20),
        appBarTheme: AppBarTheme(
          backgroundColor: _darkBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _darkTextPrimary, size: 20),
          titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
            color: _darkTextPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkNavBg,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: _darkTextTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurface2,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: _darkBorder, width: borderHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: _darkBorder, width: borderHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: _darkTextLabel),
          hintStyle: const TextStyle(color: Color(0xFF444444)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _darkSurface2,
          labelStyle: const TextStyle(color: _darkTextSecond),
          side: const BorderSide(color: _darkBorder, width: borderHairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
            side: BorderSide(color: _darkBorder, width: borderHairline),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _darkSurface,
          showDragHandle: true,
          dragHandleColor: _darkBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
          ),
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF252525),
          contentTextStyle: TextStyle(color: _darkTextPrimary),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );

  // ----------------------------------------------------------------------------
  // LIGHT THEME
  // ----------------------------------------------------------------------------
  static const _lightBg           = Color(0xFFF5F5F5);
  static const _lightSurface      = Color(0xFFFFFFFF);
  static const _lightSurface2     = Color(0xFFEFEFEF);
  static const _lightSurface3     = Color(0xFFE9E9E9);
  static const _lightBorder       = Color(0xFFE0E0E0);
  static const _lightTextPrimary  = Color(0xFF0A0A0A);
  static const _lightTextSecond   = Color(0xFF555555);
  static const _lightTextTertiary = Color(0xFF888888);
  static const _lightTextLabel    = Color(0xFF777777);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: _lightBg,
        canvasColor: _lightBg,
        colorScheme: const ColorScheme.light(
          surface: _lightSurface,
          surfaceContainerHighest: _lightSurface3,
          primary: AppColors.accent,
          onPrimary: Colors.white,
          onSurface: _lightTextPrimary,
          onSurfaceVariant: _lightTextSecond,
          secondary: AppColors.accent,
          error: AppColors.error,
          outline: _lightBorder,
        ),
        textTheme: AppTypography.textTheme.apply(
          bodyColor: _lightTextPrimary,
          displayColor: _lightTextPrimary,
        ),
        cardTheme: const CardThemeData(
          color: _lightSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
            side: BorderSide(color: _lightBorder, width: borderHairline),
          ),
        ),
        dividerColor: _lightBorder,
        dividerTheme: const DividerThemeData(
          color: _lightBorder,
          thickness: borderHairline,
          space: borderHairline,
        ),
        iconTheme: const IconThemeData(color: _lightTextSecond, size: 20),
        appBarTheme: AppBarTheme(
          backgroundColor: _lightBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _lightTextPrimary, size: 20),
          titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
            color: _lightTextPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: _lightTextTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightSurface2,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: _lightBorder, width: borderHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: _lightBorder, width: borderHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: _lightTextLabel),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _lightSurface2,
          labelStyle: const TextStyle(color: _lightTextSecond),
          side: const BorderSide(color: _lightBorder, width: borderHairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: _lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
            side: BorderSide(color: _lightBorder, width: borderHairline),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _lightSurface,
          showDragHandle: true,
          dragHandleColor: _lightBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
          ),
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
}

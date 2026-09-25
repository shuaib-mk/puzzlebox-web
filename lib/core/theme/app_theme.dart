import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => build(Brightness.light, 0);
  static ThemeData get dark => build(Brightness.dark, 0);

  static const neoPalettes = [
    Color(0xFFFACC15), // 0: Mixed Multi-Color (Default Yellow primary)
    Color(0xFFFACC15), // 1: Sunflower Yellow
    Color(0xFF4ADE80), // 2: Lime Green
    Color(0xFFF43F5E), // 3: Rose Pink
    Color(0xFF38BDF8), // 4: Electric Cyan
    Color(0xFFC084FC), // 5: Neon Violet
    Color(0xFFFB923C), // 6: Neon Orange
    Color(0xFF94A3B8), // 7: Minimal Slate
  ];

  static Color getAccentColor(Color defaultColor, int palette) {
    if (palette == 0) return defaultColor;
    return neoPalettes[palette.clamp(0, neoPalettes.length - 1)];
  }

  static ThemeData build(Brightness brightness, int palette) {
    final isDark = brightness == Brightness.dark;
    final primaryBrand = neoPalettes[palette.clamp(0, neoPalettes.length - 1)];

    final colors = ColorScheme.fromSeed(
      seedColor: primaryBrand,
      primary: primaryBrand,
      onPrimary: Colors.black,
      primaryContainer: primaryBrand,
      onPrimaryContainer: Colors.black,
      secondary: primaryBrand,
      onSecondary: Colors.black,
      secondaryContainer: isDark ? const Color(0xFF1E293B) : Colors.white,
      onSecondaryContainer: isDark ? Colors.white : Colors.black,
      brightness: brightness,
      surface: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      surfaceContainerLow: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerHigh: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      outline: Colors.black,
      outlineVariant: isDark ? Colors.white.withValues(alpha: .3) : Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PuzzleSans',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: Typography.material2021().black.apply(
        fontFamily: 'PuzzleSans',
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      iconTheme: IconThemeData(color: colors.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PuzzleSans',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -.8,
          color: colors.onSurface,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: primaryBrand,
        labelStyle: const TextStyle(
          fontFamily: 'PuzzleSans',
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: Colors.black,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'PuzzleSans',
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: Colors.black,
        ),
        side: const BorderSide(color: Colors.black, width: 2.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryBrand;
            }
            return isDark ? const Color(0xFF1E293B) : Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return isDark ? Colors.white : Colors.black;
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'PuzzleSans', fontWeight: FontWeight.w900, fontSize: 13),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: Colors.black, width: 2.2)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2.5),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'PuzzleSans', color: colors.onSurface, fontWeight: FontWeight.w800),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'PuzzleSans', color: colors.onSurfaceVariant, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrand,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'PuzzleSans',
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
          side: const BorderSide(color: Colors.black, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          foregroundColor: colors.onSurface,
          side: const BorderSide(color: Colors.black, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: Colors.black, space: 16, thickness: 2.0),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryBrand,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'PuzzleSans',
            fontSize: 12,
            letterSpacing: -.2,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'PuzzleSans',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

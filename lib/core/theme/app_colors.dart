import 'package:flutter/material.dart';

/// All named color tokens used throughout Puzzlebox.
/// Neo-Brutalism Theme Palette (inspired by Tuckii).
abstract final class AppColors {
  // ── Canvas Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFF12131A); // Dark Obsidian
  static const Color darkBackground = Color(0xFF12131A);
  static const Color lightBackground = Color(0xFFF6F6F2); // Off-White Neo Canvas

  static const Color surface = Color(0xFF1A1C26);
  static const Color darkSurface = Color(0xFF1A1C26);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color surfaceVariant = Color(0xFF242736);
  static const Color darkSurfaceVariant = Color(0xFF242736);
  static const Color lightSurfaceVariant = Color(0xFFEEEEEA);

  static const Color border = Color(0xFF000000); // Pure Neo-Brutal Black Border
  static const Color darkBorder = Color(0xFF000000);
  static const Color lightBorder = Color(0xFF000000);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color lightTextPrimary = Color(0xFF000000);

  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color lightTextSecondary = Color(0xFF525252);

  // ── Neo Accents ──────────────────────────────────────────────────────────
  static const Color brand = Color(0xFFFACC15); // Neo Sunflower Yellow
  static const Color brandLight = Color(0xFFFDE047);

  // Folder Tab Color Palette
  static const Color tabLime = Color(0xFF4ADE80);
  static const Color tabPink = Color(0xFFF43F5E);
  static const Color tabPurple = Color(0xFFC084FC);
  static const Color tabCyan = Color(0xFF38BDF8);
  static const Color tabYellow = Color(0xFFFACC15);
  static const Color tabOrange = Color(0xFFFB923C);

  // ── Tile states (Daily Five) ─────────────────────────────────────────────
  static const Color correct = Color(0xFF4ADE80);
  static const Color correctLight = Color(0xFF86EFAC);

  static const Color present = Color(0xFFFACC15);
  static const Color presentLight = Color(0xFFFDE047);

  static const Color absent = Color(0xFF242736);
  static const Color absentLight = Color(0xFFA3A3A3);

  static const Color emptyTile = Colors.transparent;
  static const Color emptyTileBorder = Color(0xFF000000);
  static const Color darkEmptyTileBorder = Color(0xFF000000);
  static const Color lightEmptyTileBorder = Color(0xFF000000);

  static const Color filledTileBorder = Color(0xFF000000);

  // ── Keyboard ────────────────────────────────────────────────────────────
  static const Color keyDefault = Color(0xFF242736);
  static const Color darkKeyDefault = Color(0xFF242736);
  static const Color lightKeyDefault = Color(0xFFE5E5E0);

  // ── Error / Danger ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFF43F5E);
  static const Color errorBg = Color(0xFF451A1A);

  // ── Game card & Connections difficulty colors ────────────────────────────
  static const Color difficultyEasy = Color(0xFFFACC15); // Yellow
  static const Color difficultyMedium = Color(0xFF4ADE80); // Lime Green
  static const Color difficultyHard = Color(0xFF38BDF8); // Cyan
  static const Color difficultyExpert = Color(0xFFC084FC); // Purple

  static const Color spangram = Color(0xFFFACC15);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

/// Persisted app-wide settings.
class SettingsNotifier extends Notifier<SettingsState> {
  Future<void> setPalette(int value) async {
    final clamped = value.clamp(0, 7);
    await ref.read(sharedPreferencesProvider).setInt('settings_palette', clamped);
    state = state.copyWith(palette: clamped);
  }

  static const _themeKey = 'settings_theme_mode';
  static const _hapticsKey = 'settings_haptics';
  static const _hardModeKey = 'settings_hard_mode';
  static const _soundKey = 'settings_sound';
  static const _difficultyKey = 'settings_default_difficulty';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    final haptics = prefs.getBool(_hapticsKey) ?? false;
    final hardMode = prefs.getBool(_hardModeKey) ?? false;
    final sound = prefs.getBool(_soundKey) ?? false;
    final defaultDifficulty = prefs.getString(_difficultyKey) ?? 'Medium';
    return SettingsState(
      themeMode: ThemeMode.values[themeIndex.clamp(0, 2)],
      palette: (prefs.getInt('settings_palette') ?? 7).clamp(0, 7),
      hapticsEnabled: haptics,
      hardModeEnabled: hardMode,
      soundEnabled: sound,
      defaultDifficulty: defaultDifficulty,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hapticsKey, enabled);
    state = state.copyWith(hapticsEnabled: enabled);
  }

  Future<void> setHardModeEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hardModeKey, enabled);
    state = state.copyWith(hardModeEnabled: enabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_soundKey, enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setDefaultDifficulty(String difficulty) async {
    if (!const ['Easy', 'Medium', 'Hard'].contains(difficulty)) return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_difficultyKey, difficulty);
    state = state.copyWith(defaultDifficulty: difficulty);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsState {
  final int palette;
  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool hardModeEnabled;
  final bool soundEnabled;
  final String defaultDifficulty;

  const SettingsState({
    this.palette = 7,
    required this.themeMode,
    this.hapticsEnabled = false,
    this.hardModeEnabled = false,
    this.soundEnabled = false,
    this.defaultDifficulty = 'Medium',
  });

  SettingsState copyWith({
    int? palette,
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? hardModeEnabled,
    bool? soundEnabled,
    String? defaultDifficulty,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hardModeEnabled: hardModeEnabled ?? this.hardModeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
    );
  }
}

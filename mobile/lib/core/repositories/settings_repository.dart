import 'package:flutter/material.dart';

/// Contract for application settings and preferences persistence.
abstract class SettingsRepository {
  ThemeMode getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);

  int getDailyGoal();
  Future<void> saveDailyGoal(int goal);

  bool getUseSerifFont();
  Future<void> saveUseSerifFont(bool value);

  bool getHapticsEnabled();
  Future<void> saveHapticsEnabled(bool value);

  bool getMorningDigestEnabled();
  Future<void> saveMorningDigestEnabled(bool value);
}

/// In-memory implementation of [SettingsRepository] with default values.
/// Can be replaced with SharedPreferences or SQLite implementation without altering UI.
class MemorySettingsRepository implements SettingsRepository {
  ThemeMode _themeMode;
  int _dailyGoal;
  bool _useSerifFont;
  bool _hapticsEnabled;
  bool _morningDigestEnabled;

  MemorySettingsRepository({
    ThemeMode initialThemeMode = ThemeMode.system,
    int initialDailyGoal = 15,
    bool initialUseSerifFont = true,
    bool initialHapticsEnabled = true,
    bool initialMorningDigestEnabled = false,
  })  : _themeMode = initialThemeMode,
        _dailyGoal = initialDailyGoal,
        _useSerifFont = initialUseSerifFont,
        _hapticsEnabled = initialHapticsEnabled,
        _morningDigestEnabled = initialMorningDigestEnabled;

  @override
  ThemeMode getThemeMode() => _themeMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }

  @override
  int getDailyGoal() => _dailyGoal;

  @override
  Future<void> saveDailyGoal(int goal) async {
    _dailyGoal = goal;
  }

  @override
  bool getUseSerifFont() => _useSerifFont;

  @override
  Future<void> saveUseSerifFont(bool value) async {
    _useSerifFont = value;
  }

  @override
  bool getHapticsEnabled() => _hapticsEnabled;

  @override
  Future<void> saveHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
  }

  @override
  bool getMorningDigestEnabled() => _morningDigestEnabled;

  @override
  Future<void> saveMorningDigestEnabled(bool value) async {
    _morningDigestEnabled = value;
  }
}

import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

/// Provider for managing reactive settings, theme mode, and reading preferences.
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  late ThemeMode _themeMode;
  late int _dailyGoal;
  late bool _useSerifFont;
  late bool _hapticsEnabled;
  late bool _morningDigestEnabled;

  ThemeMode get themeMode => _themeMode;
  int get dailyGoal => _dailyGoal;
  bool get useSerifFont => _useSerifFont;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get morningDigestEnabled => _morningDigestEnabled;

  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? MemorySettingsRepository() {
    _themeMode = _repository.getThemeMode();
    _dailyGoal = _repository.getDailyGoal();
    _useSerifFont = _repository.getUseSerifFont();
    _hapticsEnabled = _repository.getHapticsEnabled();
    _morningDigestEnabled = _repository.getMorningDigestEnabled();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _repository.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    if (_dailyGoal == goal) return;
    _dailyGoal = goal;
    await _repository.saveDailyGoal(goal);
    notifyListeners();
  }

  Future<void> toggleSerifFont(bool value) async {
    if (_useSerifFont == value) return;
    _useSerifFont = value;
    await _repository.saveUseSerifFont(value);
    notifyListeners();
  }

  Future<void> toggleHaptics(bool value) async {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    await _repository.saveHapticsEnabled(value);
    notifyListeners();
  }

  Future<void> toggleMorningDigest(bool value) async {
    if (_morningDigestEnabled == value) return;
    _morningDigestEnabled = value;
    await _repository.saveMorningDigestEnabled(value);
    notifyListeners();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Process-wide theme notifier.
/// Persists dark-mode preference to `prefs.json` via path_provider.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDark = false;
  File? _file;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Load persisted preference. Call once at startup before runApp.
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/eatcode_prefs.json');
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _isDark = (map['dark_mode'] as bool?) ?? false;
      }
    } catch (_) {}
  }

  /// Toggle dark mode and persist.
  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    try {
      await _file?.writeAsString(jsonEncode({'dark_mode': value}));
    } catch (_) {}
  }
}

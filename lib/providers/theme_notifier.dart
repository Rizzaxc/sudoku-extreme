import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _load(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    _prefs.setString(_key, next == ThemeMode.light ? 'light' : 'dark');
  }
}

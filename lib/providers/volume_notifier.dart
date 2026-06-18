import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolumeNotifier extends StateNotifier<double> {
  static const _key = 'volume';
  final SharedPreferences _prefs;

  VolumeNotifier(this._prefs) : super(_prefs.getDouble(_key) ?? 1.0);

  void set(double v) {
    state = v.clamp(0.0, 1.0);
    _prefs.setDouble(_key, state);
  }
}

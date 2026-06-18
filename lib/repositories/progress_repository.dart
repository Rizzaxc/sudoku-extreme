import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressRepository {
  const ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'puzzle_status';
  static const _bestTimeKey = 'best_time';
  static const _streakKey = 'streak';

  // Returns map of puzzleId → status (1=attempted/DNF, 2=solved).
  // Absent = never tried (available).
  Map<int, int> loadStatusMap() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> markAttempted(int id) => _update(id, 1);
  Future<void> markSolved(int id) => _update(id, 2);

  Future<void> resetAttempted() async {
    final map = loadStatusMap();
    map.removeWhere((_, v) => v == 1);
    await _save(map);
  }

  Future<void> resetAll() => _prefs.remove(_key);

  int solvedCount() => loadStatusMap().values.where((v) => v == 2).length;

  int? loadBestTime() => _prefs.getInt(_bestTimeKey);
  Future<void> saveBestTime(int seconds) => _prefs.setInt(_bestTimeKey, seconds);

  int loadStreak() => _prefs.getInt(_streakKey) ?? 0;
  Future<void> saveStreak(int streak) => _prefs.setInt(_streakKey, streak);

  Future<void> _update(int id, int status) async {
    final map = loadStatusMap();
    map[id] = status;
    await _save(map);
  }

  Future<void> _save(Map<int, int> map) async {
    final encoded = jsonEncode(map.map((k, v) => MapEntry(k.toString(), v)));
    await _prefs.setString(_key, encoded);
  }
}

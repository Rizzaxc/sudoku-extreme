import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/progress_repository.dart';
import '../repositories/puzzle_repository.dart';
import '../models/game_state.dart';
import 'game_notifier.dart';
import 'theme_notifier.dart';
import 'streak_notifier.dart';
import 'volume_notifier.dart';
import '../services/sound_service.dart';

// Overridden in main.dart with the already-loaded SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(sharedPreferencesProvider));
});

final puzzleRepositoryProvider = Provider<PuzzleRepository>(
  (_) => PuzzleRepository(),
);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(sharedPreferencesProvider));
});

final streakProvider = StateNotifierProvider<StreakNotifier, int>((ref) {
  return StreakNotifier(ref.read(progressRepositoryProvider));
});

final volumeProvider = StateNotifierProvider<VolumeNotifier, double>((ref) {
  return VolumeNotifier(ref.read(sharedPreferencesProvider));
});

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  svc.setVolume(ref.read(volumeProvider));
  ref.listen<double>(volumeProvider, (_, v) => svc.setVolume(v));
  return svc;
});

final gameNotifierProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(
    ref.watch(progressRepositoryProvider),
    ref.watch(puzzleRepositoryProvider),
    ref.watch(soundServiceProvider),
  );
});

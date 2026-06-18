import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/progress_repository.dart';

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier(this._repo) : super(_repo.loadStreak());

  final ProgressRepository _repo;

  void increment() {
    state += 1;
    _repo.saveStreak(state);
    if (state > _repo.loadBestStreak()) _repo.saveBestStreak(state);
  }

  void reset() {
    if (state == 0) return;
    state = 0;
    _repo.saveStreak(0);
  }
}

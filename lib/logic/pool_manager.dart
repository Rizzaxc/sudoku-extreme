import 'dart:math';
import '../core/constants.dart';

class PoolManager {
  static List<int> availableIds(Map<int, int> statusMap) {
    return List.generate(kTotalPuzzles, (i) => i)
        .where((id) => !statusMap.containsKey(id))
        .toList();
  }

  static int selectRandom(List<int> available) {
    assert(available.isNotEmpty);
    return available[Random().nextInt(available.length)];
  }

  // Returns a new status map after exhaustion reset.
  // Keeps solved (2), removes attempted (1) to make them available again.
  // If all puzzles are solved, clears everything.
  static Map<int, int> handleExhaustion(Map<int, int> statusMap) {
    final hasSolved = statusMap.values.any((v) => v == 2);
    if (hasSolved) {
      return Map.fromEntries(statusMap.entries.where((e) => e.value == 2));
    }
    return {};
  }
}

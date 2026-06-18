class Puzzle {
  const Puzzle({
    required this.id,
    required this.clues,
    required this.solution,
    required this.source,
  });

  final int id;
  final String clues;     // 81 chars, '0' = empty
  final String solution;  // 81 chars, '1'-'9'
  final String source;    // 'qqwing' | 'tdoku'
}

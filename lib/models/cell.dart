class Cell {
  const Cell({
    this.value = 0,
    this.pencilMarks = const {},
    this.isGiven = false,
  });

  final int value;              // 0 = empty
  final Set<int> pencilMarks;   // candidates 1–9
  final bool isGiven;

  Cell copyWith({
    int? value,
    Set<int>? pencilMarks,
    bool? isGiven,
  }) {
    return Cell(
      value: value ?? this.value,
      pencilMarks: pencilMarks ?? this.pencilMarks,
      isGiven: isGiven ?? this.isGiven,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          value == other.value &&
          isGiven == other.isGiven &&
          _setsEqual(pencilMarks, other.pencilMarks);

  @override
  int get hashCode => Object.hash(value, isGiven, Object.hashAll(pencilMarks));

  static bool _setsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.every(b.contains);
  }
}

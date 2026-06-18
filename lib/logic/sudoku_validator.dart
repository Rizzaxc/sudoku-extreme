class SudokuValidator {
  static bool isCorrectPlacement(int index, int digit, String solution) {
    return solution[index] == digit.toString();
  }

  static bool isComplete(List<dynamic> cells, String solution) {
    for (int i = 0; i < 81; i++) {
      final cell = cells[i];
      if (cell.value == 0) return false;
      if (cell.value.toString() != solution[i]) return false;
    }
    return true;
  }

  // Returns all peer indices for the given cell (same row, col, or 3×3 box).
  static List<int> peers(int index) {
    final row = index ~/ 9;
    final col = index % 9;
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    final result = <int>{};
    for (int c = 0; c < 9; c++) { result.add(row * 9 + c); }
    for (int r = 0; r < 9; r++) { result.add(r * 9 + col); }
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) { result.add(r * 9 + c); }
    }
    result.remove(index);
    return result.toList();
  }
}

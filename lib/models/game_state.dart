import 'cell.dart';
import 'game_action.dart';
import '../core/constants.dart';

enum GameStatus { idle, playing, won, lost }

class GameState {
  const GameState({
    required this.cells,
    required this.solution,
    required this.puzzleId,
    this.undoStack = const [],
    this.mistakes = 0,
    this.maxMistakes = kMaxMistakes,
    this.pencilMode = false,
    this.selectedIndex = -1,
    this.selectedDigit = 0,
    this.elapsedSeconds = 0,
    this.status = GameStatus.idle,
  });

  final List<Cell> cells;
  final String solution;
  final int puzzleId;
  final List<GameAction> undoStack;
  final int mistakes;
  final int maxMistakes;
  final bool pencilMode;
  final int selectedIndex;
  final int selectedDigit;
  final int elapsedSeconds;
  final GameStatus status;

  static GameState initial() => const GameState(
    cells: [],
    solution: '',
    puzzleId: -1,
  );

  GameState copyWith({
    List<Cell>? cells,
    String? solution,
    int? puzzleId,
    List<GameAction>? undoStack,
    int? mistakes,
    int? maxMistakes,
    bool? pencilMode,
    int? selectedIndex,
    int? selectedDigit,
    int? elapsedSeconds,
    GameStatus? status,
  }) {
    return GameState(
      cells: cells ?? this.cells,
      solution: solution ?? this.solution,
      puzzleId: puzzleId ?? this.puzzleId,
      undoStack: undoStack ?? this.undoStack,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      pencilMode: pencilMode ?? this.pencilMode,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedDigit: selectedDigit ?? this.selectedDigit,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
    );
  }
}

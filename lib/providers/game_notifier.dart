import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/puzzle.dart';
import '../logic/pool_manager.dart';
import '../logic/sudoku_validator.dart';
import '../repositories/progress_repository.dart';
import '../repositories/puzzle_repository.dart';
import '../services/sound_service.dart';

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._progressRepo, this._puzzleRepo, this._sound)
      : super(GameState.initial());

  final ProgressRepository _progressRepo;
  final PuzzleRepository _puzzleRepo;
  final SoundService _sound;
  Timer? _ticker;
  DateTime? _gameStartTime;

  void _startTimer() {
    _ticker?.cancel();
    _gameStartTime = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == GameStatus.playing && _gameStartTime != null) {
        state = state.copyWith(
          elapsedSeconds:
              DateTime.now().difference(_gameStartTime!).inSeconds,
        );
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
  // Returns the loaded puzzle for GameScreen to use.
  Future<Puzzle> initGame() async {
    var statusMap = _progressRepo.loadStatusMap();
    var available = PoolManager.availableIds(statusMap);

    if (available.isEmpty) {
      final reset = PoolManager.handleExhaustion(statusMap);
      await _progressRepo.resetAttempted();
      if (!reset.values.any((v) => v != 2)) {
        await _progressRepo.resetAll();
      }
      statusMap = _progressRepo.loadStatusMap();
      available = PoolManager.availableIds(statusMap);
    }

    final selectedId = PoolManager.selectRandom(available);
    // Mark immediately — crash/kill = DNF automatically.
    await _progressRepo.markAttempted(selectedId);

    final puzzle = await _puzzleRepo.loadPuzzle(selectedId);
    _buildBoard(puzzle);
    return puzzle;
  }

  void _buildBoard(Puzzle puzzle) {
    final cells = List.generate(81, (i) {
      final ch = puzzle.clues[i];
      final value = int.parse(ch);
      return Cell(value: value, isGiven: value != 0);
    });
    state = state.copyWith(
      cells: cells,
      solution: puzzle.solution,
      puzzleId: puzzle.id,
      undoStack: const [],
      mistakes: 0,
      pencilMode: false,
      selectedIndex: -1,
      elapsedSeconds: 0,
      status: GameStatus.playing,
    );
    _startTimer();
    _sound.playStart();
  }

  // Tapping a cell places the selected digit, pencil-marks, or erases based on active mode.
  void selectCell(int index) {
    if (state.cells.isEmpty || state.status != GameStatus.playing) return;
    final cell = state.cells[index];

    // Apply pending erase if this cell is erasable
    if (state.pendingErase) {
      if (!cell.isGiven && (cell.isError || cell.pencilMarks.isNotEmpty)) {
        _doErase(index);
        state = state.copyWith(selectedIndex: index);
        return;
      }
      state = state.copyWith(pendingErase: false);
    }

    // Correctly filled cell: select + pick up digit, unless the digit is exhausted
    if (cell.value != 0 && !cell.isError) {
      final count =
          state.cells.where((c) => c.value == cell.value && !c.isError).length;
      if (count < 9) {
        state = state.copyWith(selectedIndex: index, selectedDigit: cell.value);
      } else {
        state = state.copyWith(selectedIndex: index);
      }
      return;
    }

    state = state.copyWith(selectedIndex: index);

    if (cell.isGiven) return;
    final digit = state.selectedDigit;
    if (digit == 0) return;
    if (state.pencilMode) {
      if (cell.isError) return;
      _togglePencil(index, digit);
    } else {
      final isCorrect =
          SudokuValidator.isCorrectPlacement(index, digit, state.solution);
      if (cell.isError) {
        // Error cells only accept the correct digit; wrong digit is silently ignored
        if (isCorrect) _placeCorrect(index, digit);
      } else {
        if (isCorrect) {
          _placeCorrect(index, digit);
        } else {
          _registerMistake(index, digit);
        }
      }
    }
  }

  void selectDigit(int digit) {
    state = state.copyWith(
      selectedDigit: state.selectedDigit == digit ? 0 : digit,
    );
  }

  void _placeCorrect(int idx, int digit) {
    final cells = List<Cell>.from(state.cells);

    // Collect peer pencil marks that will be cleared.
    final clearedPeerMarks = <int, Set<int>>{};
    for (final peer in SudokuValidator.peers(idx)) {
      final peerMarks = cells[peer].pencilMarks;
      if (peerMarks.contains(digit)) {
        clearedPeerMarks[peer] = Set<int>.from(peerMarks);
        cells[peer] = cells[peer].copyWith(
          pencilMarks: Set<int>.from(peerMarks)..remove(digit),
        );
      }
    }

    cells[idx] = cells[idx].copyWith(value: digit, pencilMarks: const {}, isError: false);

    // Correct placements are permanent — not tracked in the undo stack.
    GameStatus newStatus = state.status;
    if (SudokuValidator.isComplete(cells, state.solution)) {
      newStatus = GameStatus.won;
      _progressRepo.markSolved(state.puzzleId);
      _stopTimer();
      final best = _progressRepo.loadBestTime();
      if (best == null || state.elapsedSeconds < best) {
        _progressRepo.saveBestTime(state.elapsedSeconds);
      }
      _sound.playWin();
    } else {
      _sound.playPlace();
    }

    state = state.copyWith(cells: cells, status: newStatus);

    // Auto-deselect the digit once all 9 of it are placed
    if (newStatus != GameStatus.won &&
        state.selectedDigit == digit &&
        state.cells.where((c) => c.value == digit).length == 9) {
      state = state.copyWith(selectedDigit: 0);
    }
  }

  void _registerMistake(int idx, int digit) {
    final newMistakes = state.mistakes + 1;
    final isLost = newMistakes >= state.maxMistakes;
    final newStatus = isLost ? GameStatus.lost : state.status;
    if (isLost) {
      _stopTimer();
      _sound.playLose();
    } else {
      _sound.playMistake();
    }
    // Show the wrong digit in red on the cell; no undo entry (mistakes are permanent).
    final cells = List<Cell>.from(state.cells);
    cells[idx] = cells[idx].copyWith(
      value: digit,
      isError: true,
      pencilMarks: const {},
    );
    state = state.copyWith(cells: cells, mistakes: newMistakes, status: newStatus);
  }

  void _togglePencil(int idx, int digit) {
    final cell = state.cells[idx];
    if (cell.value != 0) return; // don't pencil on a filled cell
    final wasPresent = cell.pencilMarks.contains(digit);
    final newMarks = Set<int>.from(cell.pencilMarks);
    if (wasPresent) {
      newMarks.remove(digit);
    } else {
      newMarks.add(digit);
    }
    final cells = List<Cell>.from(state.cells);
    cells[idx] = cell.copyWith(pencilMarks: newMarks);

    final action = TogglePencilMark(
      index: idx,
      digit: digit,
      wasPresent: wasPresent,
    );
    final newUndo = List<GameAction>.from(state.undoStack)..add(action);
    state = state.copyWith(cells: cells, undoStack: newUndo);
    _sound.playPencil();
  }

  void erase() {
    final idx = state.selectedIndex;
    if (idx < 0 || state.cells.isEmpty) return;
    final cell = state.cells[idx];

    // Completed cells (given or correct placement) can't be erased directly —
    // queue the erase so it fires on the next tapped erasable cell.
    if (cell.isGiven || (!cell.isError && cell.value > 0)) {
      state = state.copyWith(pendingErase: true);
      return;
    }

    if (!cell.isError && cell.pencilMarks.isEmpty) return;
    _doErase(idx);
  }

  void _doErase(int idx) {
    final cell = state.cells[idx];
    final action = EraseCell(
      index: idx,
      prevValue: cell.value,
      prevIsError: cell.isError,
      prevPencilMarks: Set<int>.from(cell.pencilMarks),
    );
    final cells = List<Cell>.from(state.cells);
    cells[idx] = cell.copyWith(value: 0, isError: false, pencilMarks: const {});
    final newUndo = List<GameAction>.from(state.undoStack)..add(action);
    state = state.copyWith(cells: cells, undoStack: newUndo, pendingErase: false);
    _sound.playErase();
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final newUndo = List<GameAction>.from(state.undoStack);
    final action = newUndo.removeLast();
    final cells = List<Cell>.from(state.cells);

    switch (action) {
      case PlaceValue(:final index, :final prevPencilMarks, :final clearedPeerMarks):
        cells[index] = cells[index].copyWith(value: 0, pencilMarks: prevPencilMarks);
        for (final entry in clearedPeerMarks.entries) {
          cells[entry.key] = cells[entry.key].copyWith(pencilMarks: entry.value);
        }
      case TogglePencilMark(:final index, :final digit, :final wasPresent):
        final marks = Set<int>.from(cells[index].pencilMarks);
        if (wasPresent) {
          marks.add(digit);
        } else {
          marks.remove(digit);
        }
        cells[index] = cells[index].copyWith(pencilMarks: marks);
      case EraseCell(:final index, :final prevValue, :final prevIsError, :final prevPencilMarks):
        cells[index] = cells[index].copyWith(
          value: prevValue,
          isError: prevIsError,
          pencilMarks: prevPencilMarks,
        );
    }

    state = state.copyWith(cells: cells, undoStack: newUndo);
  }

  void togglePencilMode() {
    state = state.copyWith(pencilMode: !state.pencilMode);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/providers.dart';
import '../models/game_state.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/action_bar.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/background_choice_dialog.dart';

IconData _volumeIcon(double v) {
  if (v == 0) return LucideIcons.volumeX;
  if (v < 0.5) return LucideIcons.volume1;
  return LucideIcons.volume2;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.puzzleId});
  final int puzzleId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _backgroundDialogShowing = false;
  bool _gameOverShown = false;

  final _volumeLayerLink = LayerLink();
  OverlayEntry? _volumeOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _dismissVolumePopup();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.inactive) {
      _dismissVolumePopup();
      _maybeShowBackgroundDialog();
    }
  }

  void _maybeShowBackgroundDialog() {
    if (_backgroundDialogShowing) return;
    final gameState = ref.read(gameNotifierProvider);
    if (gameState.status != GameStatus.playing) return;
    if (!mounted) return;

    _backgroundDialogShowing = true;
    showBackgroundChoiceDialog(context).then((choice) {
      _backgroundDialogShowing = false;
      if (!mounted) return;
      if (choice == BackgroundChoice.quit) {
        final gs = ref.read(gameNotifierProvider);
        if (gs.undoStack.isNotEmpty || gs.mistakes > 0) {
          ref.read(streakProvider.notifier).reset();
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ref.read(streakProvider.notifier).reset();
      }
    });
  }

  static int _computeScore(int healthRemaining, int elapsedSeconds) {
    final timePenalty = (elapsedSeconds ~/ healthRemaining) + elapsedSeconds;
    return (1000 + 500 * healthRemaining - timePenalty).clamp(0, 9999);
  }

  void _handleGameOver(BuildContext context, GameState gameState) {
    if (_gameOverShown) return;
    _gameOverShown = true;

    int? score;
    if (gameState.status == GameStatus.won) {
      ref.read(streakProvider.notifier).increment();
      final health = gameState.maxMistakes - gameState.mistakes;
      score = _computeScore(health, gameState.elapsedSeconds);
      final repo = ref.read(progressRepositoryProvider);
      final best = repo.loadBestScore();
      if (best == null || score > best) repo.saveBestScore(score);
    } else {
      ref.read(streakProvider.notifier).reset();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGameOverDialog(
        context,
        won: gameState.status == GameStatus.won,
        mistakes: gameState.mistakes,
        score: score,
        onHome: () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      );
    });
  }

  void _toggleVolumePopup(ShadThemeData theme) {
    if (_volumeOverlay != null) {
      _dismissVolumePopup();
      return;
    }

    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? Colors.amber : Colors.blue;

    _volumeOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Transparent barrier — tap outside to dismiss
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissVolumePopup,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _volumeLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Material(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(12),
              elevation: 6,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Consumer(
                  builder: (overlayCtx, ref, _) {
                    final volume = ref.watch(volumeProvider);
                    return SizedBox(
                      width: 32,
                      height: 160,
                      child: RotatedBox(
                        // quarterTurns: 3 → dragging up increases value
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: accent,
                            inactiveTrackColor: theme.colorScheme.muted,
                            thumbColor: accent,
                            overlayColor: accent.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: volume,
                            onChanged: (v) =>
                                ref.read(volumeProvider.notifier).set(v),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_volumeOverlay!);
  }

  void _dismissVolumePopup() {
    _volumeOverlay?.remove();
    _volumeOverlay = null;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final theme = ShadTheme.of(context);

    if ((gameState.status == GameStatus.won ||
            gameState.status == GameStatus.lost) &&
        !_gameOverShown) {
      _handleGameOver(context, gameState);
    }

    final isActive = gameState.status == GameStatus.playing;

    // digitCounts[d] = correct placements of digit d (errors excluded)
    final digitCounts = List.filled(10, 0);
    for (final cell in gameState.cells) {
      if (cell.value > 0 && !cell.isError) digitCounts[cell.value]++;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (gameState.status == GameStatus.playing &&
              (gameState.undoStack.isNotEmpty || gameState.mistakes > 0)) {
            ref.read(streakProvider.notifier).reset();
          }
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          leading: ShadButton.ghost(
            onPressed: () {
              if (gameState.status == GameStatus.playing) {
                ref.read(streakProvider.notifier).reset();
              }
              Navigator.of(context).pop();
            },
            child: const Icon(LucideIcons.arrowLeft),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Puzzle #${widget.puzzleId + 1}', style: theme.textTheme.large),
              Text(
                _formatTime(gameState.elapsedSeconds),
                style: theme.textTheme.muted,
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            CompositedTransformTarget(
              link: _volumeLayerLink,
              child: Consumer(
                builder: (ctx, ref, _) {
                  final volume = ref.watch(volumeProvider);
                  return ShadButton.ghost(
                    onPressed: () => _toggleVolumePopup(theme),
                    child: Icon(_volumeIcon(volume)),
                  );
                },
              ),
            ),
          ],
        ),
        body: gameState.cells.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gridSize = (constraints.maxHeight - 240)
                        .clamp(100.0, constraints.maxWidth - 24);
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: gridSize + 24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              SizedBox(
                                width: gridSize,
                                height: gridSize,
                                child: SudokuGrid(
                                  cells: gameState.cells,
                                  selectedIndex: gameState.selectedIndex,
                                  selectedDigit: gameState.selectedDigit,
                                  onCellTap: notifier.selectCell,
                                ),
                              ),
                              ActionBar(
                                mistakes: gameState.mistakes,
                                maxMistakes: gameState.maxMistakes,
                                pencilMode: gameState.pencilMode,
                                canUndo: gameState.undoStack.isNotEmpty && isActive,
                                pendingErase: gameState.pendingErase,
                                onUndo: notifier.undo,
                                onTogglePencil: notifier.togglePencilMode,
                                onErase: notifier.erase,
                              ),
                              NumberPad(
                                enabled: isActive,
                                selectedDigit: gameState.selectedDigit,
                                digitCounts: digitCounts,
                                onDigit: notifier.selectDigit,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

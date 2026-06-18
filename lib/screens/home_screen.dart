import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/providers.dart';
import '../core/constants.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _solvedCount = 0;
  int? _bestTime;
  int? _bestScore;
  int _bestStreak = 0;

  void _refreshStats() {
    if (!mounted) return;
    final repo = ref.read(progressRepositoryProvider);
    setState(() {
      _solvedCount = repo.solvedCount();
      _bestTime = repo.loadBestTime();
      _bestScore = repo.loadBestScore();
      _bestStreak = repo.loadBestStreak();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshStats();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final streak = ref.watch(streakProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Theme toggle — top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: ShadButton.ghost(
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
                child: Icon(
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  size: 20,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sudoku Extreme', style: theme.textTheme.h1),
                    const SizedBox(height: 8),
                    Text(
                      '$_solvedCount / $kTotalPuzzles solved',
                      style: theme.textTheme.muted,
                    ),
                    const SizedBox(height: 40),
                    ShadButton(
                      onPressed: _startGame,
                      leading: const Icon(LucideIcons.play),
                      child: const Text('Play'),
                    ),
                    const SizedBox(height: 32),
                    Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 8, bottom: 10),
                            child: Icon(LucideIcons.timer,
                                size: 16,
                                color: theme.colorScheme.mutedForeground),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 20, bottom: 10),
                            child: Text('Best Time',
                                style: theme.textTheme.muted),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _bestTime != null
                                ? Text(_formatTime(_bestTime!),
                                    style: theme.textTheme.p)
                                : Icon(LucideIcons.infinity,
                                    size: 16,
                                    color:
                                        theme.colorScheme.mutedForeground),
                          ),
                        ]),
                        TableRow(children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 8, bottom: 10),
                            child: Icon(LucideIcons.flame,
                                size: 16,
                                color: theme.colorScheme.mutedForeground),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 20, bottom: 10),
                            child: Text('Best Streak',
                                style: theme.textTheme.muted),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: '$_bestStreak',
                                  style: theme.textTheme.p),
                              TextSpan(
                                  text: '  (Current: $streak)',
                                  style: theme.textTheme.muted),
                            ])),
                          ),
                        ]),
                        TableRow(children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(LucideIcons.star,
                                size: 16,
                                color: theme.colorScheme.mutedForeground),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text('Best Score',
                                style: theme.textTheme.muted),
                          ),
                          Text('${_bestScore ?? 0}',
                              style: theme.textTheme.p),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGame() async {
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    final toaster = ShadToaster.of(context);
    try {
      final puzzle = await gameNotifier.initGame();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GameScreen(puzzleId: puzzle.id),
        ),
      );
      _refreshStats();
    } catch (e) {
      if (!mounted) return;
      toaster.show(
        ShadToast.destructive(
          title: const Text('Failed to load puzzle'),
          description: Text('$e'),
        ),
      );
    }
  }
}

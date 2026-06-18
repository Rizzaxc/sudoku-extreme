import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> showGameOverDialog(
  BuildContext context, {
  required bool won,
  required int mistakes,
  required VoidCallback onHome,
  int? score,
}) {
  final theme = ShadTheme.of(context);
  return showShadDialog(
    context: context,
    builder: (context) => ShadDialog.alert(
      title: Text(won ? 'Puzzle Solved!' : 'Game Over'),
      description: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won
                  ? 'Great job! You solved it with $mistakes mistake${mistakes == 1 ? '' : 's'}.'
                  : 'You used all $mistakes mistakes. Better luck next time!',
            ),
            if (won && score != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.star,
                      size: 16, color: theme.colorScheme.mutedForeground),
                  const SizedBox(width: 6),
                  Text('Score: $score', style: theme.textTheme.p),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        ShadButton(
          onPressed: () {
            Navigator.of(context).pop();
            onHome();
          },
          child: const Text('Back to Home'),
        ),
      ],
    ),
  );
}

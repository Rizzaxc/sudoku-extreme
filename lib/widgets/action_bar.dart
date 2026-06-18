import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.mistakes,
    required this.maxMistakes,
    required this.pencilMode,
    required this.canUndo,
    required this.onUndo,
    required this.onTogglePencil,
    required this.onErase,
  });

  final int mistakes;
  final int maxMistakes;
  final bool pencilMode;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onTogglePencil;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final actionColor = isDark ? Colors.amber : Colors.blue;

    final remaining = maxMistakes - mistakes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Start: Undo + Erase
          ShadButton.ghost(
            enabled: canUndo,
            onPressed: onUndo,
            leading: Icon(LucideIcons.undo2, size: 20, color: actionColor),
            child: Text('Undo', style: TextStyle(color: actionColor)),
          ),
          ShadButton.ghost(
            onPressed: onErase,
            leading: Icon(LucideIcons.eraser, size: 20, color: actionColor),
            child: Text('Erase', style: TextStyle(color: actionColor)),
          ),
          // Center: Pencil — primary when active, muted when inactive
          Expanded(
            child: Center(
              child: ShadButton.ghost(
                onPressed: onTogglePencil,
                leading: Icon(
                  LucideIcons.pencil,
                  size: 20,
                  color: pencilMode
                      ? colorScheme.primary
                      : colorScheme.mutedForeground,
                ),
                child: Text(
                  'Pencil',
                  style: TextStyle(
                    color: pencilMode
                        ? colorScheme.primary
                        : colorScheme.mutedForeground,
                    fontWeight: pencilMode ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ),
          ),
          // End: Hearts — filled for remaining lives, cracked for used
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxMistakes, (i) {
              final isFilled = i < remaining;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  isFilled ? Icons.favorite : LucideIcons.heartCrack,
                  size: 22,
                  color: isFilled
                      ? Colors.red
                      : colorScheme.mutedForeground,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

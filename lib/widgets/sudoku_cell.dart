import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/cell.dart';

class SudokuCell extends StatelessWidget {
  const SudokuCell({
    super.key,
    required this.cell,
    required this.index,
    required this.isSelected,
    required this.isPeer,
    required this.isMatchingDigit,
    required this.onTap,
  });

  final Cell cell;
  final int index;
  final bool isSelected;
  final bool isPeer;
  final bool isMatchingDigit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;
    Color bgColor;
    if (isSelected) {
      bgColor = colorScheme.primary.withValues(alpha: 0.25);
    } else if (isMatchingDigit) {
      // Warm/cool accent tint — visually distinct from the gray peer highlight
      bgColor = isDark
          ? Colors.amber.withValues(alpha: 0.22)
          : Colors.blue.withValues(alpha: 0.18);
    } else if (isPeer) {
      bgColor = colorScheme.muted.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: bgColor),
        child: cell.value != 0
            ? _buildValue(context, theme, colorScheme)
            : cell.pencilMarks.isNotEmpty
                ? _buildPencilMarks(theme, colorScheme)
                : const SizedBox.expand(),
      ),
    );
  }

  Widget _buildValue(
      BuildContext context, ShadThemeData theme, ShadColorScheme colorScheme) {
    final Color color;
    final FontWeight fontWeight;
    final FontStyle fontStyle;

    if (cell.isError) {
      color = Colors.red;
      fontWeight = FontWeight.w500;
      fontStyle = FontStyle.italic;
    } else if (cell.isGiven) {
      color = colorScheme.foreground;
      fontWeight = FontWeight.w700;
      fontStyle = FontStyle.normal;
    } else {
      color = colorScheme.primary;
      fontWeight = FontWeight.w500;
      fontStyle = FontStyle.normal;
    }

    return Center(
      child: Text(
        '${cell.value}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPencilMarks(ShadThemeData theme, ShadColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      children: List.generate(9, (i) {
        final digit = i + 1;
        final has = cell.pencilMarks.contains(digit);
        return Center(
          child: Text(
            has ? '$digit' : '',
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.mutedForeground,
              height: 1.0,
            ),
          ),
        );
      }),
    );
  }
}

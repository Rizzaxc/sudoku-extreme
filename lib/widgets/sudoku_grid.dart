import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/cell.dart';
import '../logic/sudoku_validator.dart';
import 'sudoku_cell.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    super.key,
    required this.cells,
    required this.selectedIndex,
    required this.onCellTap,
  });

  final List<Cell> cells;
  final int selectedIndex;
  final void Function(int index) onCellTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final borderColor = theme.colorScheme.border;
    final thickBorder = BorderSide(color: borderColor, width: 3.0);
    final thinBorder = BorderSide(color: borderColor, width: 1.0);

    final selectedPeers = selectedIndex >= 0
        ? SudokuValidator.peers(selectedIndex).toSet()
        : const <int>{};
    final selectedValue =
        selectedIndex >= 0 ? cells[selectedIndex].value : 0;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(thickBorder),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = index ~/ 9;
            final col = index % 9;

            final border = Border(
              right: col == 8
                  ? BorderSide.none
                  : (col == 2 || col == 5) ? thickBorder : thinBorder,
              bottom: row == 8
                  ? BorderSide.none
                  : (row == 2 || row == 5) ? thickBorder : thinBorder,
            );

            final isPeer = selectedPeers.contains(index);
            final isSameValue =
                selectedValue != 0 && cells[index].value == selectedValue;

            return Container(
              decoration: BoxDecoration(border: border),
              child: SudokuCell(
                cell: cells[index],
                index: index,
                isSelected: index == selectedIndex,
                isPeer: isPeer,
                isSameValue: isSameValue && index != selectedIndex,
                onTap: () => onCellTap(index),
              ),
            );
          },
        ),
      ),
    );
  }
}

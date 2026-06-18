import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.selectedDigit,
    this.enabled = true,
  });

  final void Function(int digit) onDigit;
  final int selectedDigit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            children: [
              for (int col = 0; col < 3; col++)
                Expanded(
                  child: _DigitButton(
                    digit: row * 3 + col + 1,
                    isSelected: selectedDigit == row * 3 + col + 1,
                    enabled: enabled,
                    onTap: () => onDigit(row * 3 + col + 1),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.digit,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final int digit;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      '$digit',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );

    return Padding(
      padding: const EdgeInsets.all(3),
      child: isSelected
          ? ShadButton(
              enabled: enabled,
              padding: EdgeInsets.zero,
              onPressed: onTap,
              child: child,
            )
          : ShadButton.outline(
              enabled: enabled,
              padding: EdgeInsets.zero,
              onPressed: onTap,
              child: child,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum BackgroundChoice { idle, quit }

Future<BackgroundChoice> showBackgroundChoiceDialog(BuildContext context) async {
  final result = await showShadDialog<BackgroundChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ShadDialog.alert(
      title: const Text('Leave game?'),
      description: const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Idle keeps your progress. Quit marks this puzzle as DNF.',
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(BackgroundChoice.idle),
          child: const Text('Idle'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop(BackgroundChoice.quit),
          child: const Text('Quit'),
        ),
      ],
    ),
  );
  return result ?? BackgroundChoice.idle;
}

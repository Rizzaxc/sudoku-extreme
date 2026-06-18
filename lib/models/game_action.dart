sealed class GameAction {
  const GameAction();
}

// Only correct placements enter the undo stack.
final class PlaceValue extends GameAction {
  const PlaceValue({
    required this.index,
    required this.newValue,
    required this.prevPencilMarks,
    required this.clearedPeerMarks,
  });

  final int index;
  final int newValue;
  final Set<int> prevPencilMarks;
  // peer index → marks that were removed from that peer
  final Map<int, Set<int>> clearedPeerMarks;
}

final class TogglePencilMark extends GameAction {
  const TogglePencilMark({
    required this.index,
    required this.digit,
    required this.wasPresent,
  });

  final int index;
  final int digit;
  final bool wasPresent;
}

final class EraseCell extends GameAction {
  const EraseCell({
    required this.index,
    required this.prevValue,
    required this.prevPencilMarks,
  });

  final int index;
  final int prevValue;
  final Set<int> prevPencilMarks;
}

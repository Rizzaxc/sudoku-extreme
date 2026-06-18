import 'package:flutter/services.dart';
import '../core/chunk_locator.dart';
import '../models/puzzle.dart';

class PuzzleRepository {
  Future<Puzzle> loadPuzzle(int id) async {
    final chunkIdx = ChunkLocator.chunkIndex(id);
    final assetPath = ChunkLocator.chunkAssetPath(chunkIdx);
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw.split('\n');
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 4) continue;
      if (int.tryParse(parts[0]) == id) {
        return Puzzle(
          id: id,
          clues: parts[1].trim(),
          solution: parts[2].trim(),
          source: parts[3].trim(),
        );
      }
    }
    throw StateError('Puzzle $id not found in $assetPath');
  }
}

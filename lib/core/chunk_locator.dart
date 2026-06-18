import 'constants.dart';

class ChunkLocator {
  static int chunkIndex(int puzzleId) => puzzleId ~/ kChunkSize;

  static String chunkAssetPath(int chunkIdx) {
    final padded = chunkIdx.toString().padLeft(2, '0');
    return 'assets/puzzles/chunk_$padded.csv';
  }
}

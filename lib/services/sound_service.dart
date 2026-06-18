import 'package:audioplayers/audioplayers.dart';

class SoundService {
  // Pool of 3 prevents dropped sounds on rapid placements.
  // ReleaseMode.stop keeps the native MediaPlayer allocated between calls.
  static const _placePoolSize = 3;
  final List<AudioPlayer> _placePool =
      List.generate(_placePoolSize, (_) => AudioPlayer());
  int _placeIdx = 0;
  double _volume = 1.0;

  final AudioPlayer _pencil  = AudioPlayer();
  final AudioPlayer _erase   = AudioPlayer();
  final AudioPlayer _win     = AudioPlayer();
  final AudioPlayer _lose    = AudioPlayer();
  final AudioPlayer _mistake = AudioPlayer();
  final AudioPlayer _start   = AudioPlayer();

  SoundService() {
    for (final p in [
      ..._placePool, _pencil, _erase, _win, _lose, _mistake, _start,
    ]) {
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  void setVolume(double v) => _volume = v.clamp(0.0, 1.0);

  void _play(AudioPlayer p, String file) {
    p.setVolume(_volume);
    p.play(AssetSource('sounds/$file'));
  }

  void playPlace() {
    _play(_placePool[_placeIdx], 'place.wav');
    _placeIdx = (_placeIdx + 1) % _placePoolSize;
  }

  void playPencil()  => _play(_pencil,  'pencil.wav');
  void playErase()   => _play(_erase,   'erase.wav');
  void playWin()     => _play(_win,     'win.wav');
  void playLose()    => _play(_lose,    'lose.wav');
  void playMistake() => _play(_mistake, 'mistake.wav');
  void playStart()   => _play(_start,   'start.wav');

  void dispose() {
    for (final p in [
      ..._placePool, _pencil, _erase, _win, _lose, _mistake, _start,
    ]) {
      p.dispose();
    }
  }
}

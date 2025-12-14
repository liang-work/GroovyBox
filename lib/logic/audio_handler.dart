import 'package:media_kit/media_kit.dart';

class AudioHandler {
  final Player _player;

  AudioHandler() : _player = Player() {
    // Configure for audio
    // _player.setPlaylistMode(PlaylistMode.loop); // Optional
  }

  Player get player => _player;

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSource(String path) async {
    await _player.open(Media(path));
  }

  void dispose() {
    _player.dispose();
  }
}

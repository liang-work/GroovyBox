import 'package:groovybox/logic/audio_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_provider.g.dart';

// This should be set after AudioService.init in main.dart
late AudioHandler _audioHandler;

@Riverpod(keepAlive: true)
AudioHandler audioHandler(Ref ref) {
  return _audioHandler;
}

// Function to set the audio handler after initialization
void setAudioHandler(AudioHandler handler) {
  _audioHandler = handler;
}

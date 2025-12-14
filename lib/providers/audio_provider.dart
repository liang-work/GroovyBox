import 'package:groovybox/logic/audio_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_provider.g.dart';

@Riverpod(keepAlive: true)
AudioHandler audioHandler(Ref ref) {
  final handler = AudioHandler();
  ref.onDispose(() => handler.dispose());
  return handler;
}

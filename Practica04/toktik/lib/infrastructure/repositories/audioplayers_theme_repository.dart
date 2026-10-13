import 'package:audioplayers/audioplayers.dart';

import '../../domain/repositories/theme_audio_repository.dart';

class AudioplayersThemeRepository implements ThemeAudioRepository {
  final AudioPlayer player = AudioPlayer();
  @override
  Future<void> play(String asset) async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(.12);
    await player.play(AssetSource(asset));
  }

  @override
  Future<void> stop() => player.stop();
  @override
  Future<void> dispose() => player.dispose();
}

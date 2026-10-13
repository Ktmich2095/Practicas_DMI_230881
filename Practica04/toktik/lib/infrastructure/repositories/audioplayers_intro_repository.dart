import 'package:audioplayers/audioplayers.dart';

import '../../domain/repositories/intro_audio_repository.dart';

class AudioplayersIntroRepository implements IntroAudioRepository {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> playOnce(String asset) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(.22);
    await _player.play(AssetSource(asset));
  }

  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}

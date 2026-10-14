import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../../domain/repositories/intro_audio_repository.dart';

class AudioplayersIntroRepository implements IntroAudioRepository {
  AudioPlayer? _player;
  @override
  Future<void> playOnce(String asset) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!manifest.listAssets().contains('assets/$asset')) return;
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(.22);
      await player.play(AssetSource(asset));
    } catch (_) {
      // Missing, invalid or unsupported welcome audio must not block startup.
      try {
        await stop();
      } catch (_) {
        // Audio is optional, including on platforms without a player backend.
      }
    }
  }

  @override
  Future<void> stop() async => _player?.stop();
  @override
  Future<void> dispose() async => _player?.dispose();
}

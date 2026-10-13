import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:toktik_app/domain/entities/video_post.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';

class FakePlayer extends VideoPlayerController {
  bool released = false;
  FakePlayer(super.dataSource) : super.asset();
  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> setLooping(bool looping) async {
    value = value.copyWith(isLooping: looping);
  }

  @override
  // This fake owns no native player; calling the plugin would need a platform.
  // ignore: must_call_super
  Future<void> dispose() async {
    released = true;
  }
}

class SlowPlayer extends FakePlayer {
  final Completer<void> ready;
  SlowPlayer(super.dataSource, this.ready);
  @override
  Future<void> initialize() async {
    await ready.future;
    await super.initialize();
  }
}

void main() {
  test(
    'Changing target during initialization never starts the old video',
    () async {
      final ready = Completer<void>();
      final created = <String, FakePlayer>{};
      final coordinator = PlaybackCoordinator(
        createController: (video) {
          final player = video.id == 'first'
              ? SlowPlayer(video.id, ready)
              : FakePlayer(video.id);
          created[video.id] = player;
          return player;
        },
      );
      const videos = [
        VideoPost(caption: 'First', videoUrl: 'first'),
        VideoPost(caption: 'Second', videoUrl: 'second'),
      ];
      final initial = coordinator.select(videos, 0);
      await Future<void>.delayed(Duration.zero);
      final next = coordinator.select(videos, 1);
      ready.complete();
      await initial;
      await next;
      expect(created['first']!.value.isPlaying, isFalse);
      expect(created['second']!.value.isPlaying, isTrue);
      coordinator.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'Only visible video plays; bounded preload, lifecycle and disposal',
    () async {
      final created = <FakePlayer>[];
      final coordinator = PlaybackCoordinator(
        createController: (video) {
          final player = FakePlayer(video.videoUrl);
          created.add(player);
          return player;
        },
      );
      final videos = List.generate(
        5,
        (i) => VideoPost(caption: '$i', videoUrl: '$i.mp4'),
      );
      await coordinator.select(videos, 0);
      expect(coordinator.controllers.length, 2);
      expect(created.where((p) => p.value.isPlaying).length, 1);
      await coordinator.select(videos, 2);
      expect(coordinator.controllers.length, 3);
      expect(created.first.released, isTrue);
      expect(created.where((p) => p.value.isPlaying).length, 1);
      await coordinator.lifecycle(false);
      expect(created.where((p) => p.value.isPlaying), isEmpty);
      await coordinator.lifecycle(true);
      expect(coordinator.current!.value.isPlaying, isTrue);
      await coordinator.togglePause();
      await coordinator.lifecycle(false);
      await coordinator.lifecycle(true);
      expect(coordinator.current!.value.isPlaying, isFalse);
      await coordinator.toggleSound();
      expect(coordinator.current!.value.volume, 1);
      coordinator.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(created.every((p) => p.released), isTrue);
    },
  );
}

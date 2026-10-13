import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/video_post.dart';

/// All player operations are serialized. Only the visible player may play.
class PlaybackCoordinator extends ChangeNotifier {
  final VideoPlayerController Function(VideoPost) createController;
  final Future<void> Function(bool audible)? coordinateAudio;
  final Future<bool> Function(bool muted)? persistMuted;
  PlaybackCoordinator({
    VideoPlayerController Function(VideoPost)? createController,
    this.coordinateAudio,
    this.persistMuted,
    bool initiallyMuted = true,
  }) : createController = createController ?? _defaultController {
    muted = initiallyMuted;
  }
  static VideoPlayerController _defaultController(VideoPost video) =>
      video.videoUrl.startsWith("https://")
      ? VideoPlayerController.networkUrl(Uri.parse(video.videoUrl))
      : VideoPlayerController.asset(video.videoUrl);
  final Map<String, VideoPlayerController> controllers = {};
  final Set<String> errors = {};
  List<VideoPost> _videos = [];
  int _index = 0;
  bool muted = true, paused = false, foreground = true, _closed = false;
  Future<void> _queue = Future.value();
  VideoPlayerController? get current =>
      _videos.isEmpty ? null : controllers[_videos[_index].id];
  Future<void> select(List<VideoPost> videos, int index) {
    _pauseImmediately();
    _videos = List.of(videos);
    _index = index;
    paused = false;
    return _schedule();
  }

  Future<void> updateVideos(List<VideoPost> videos, int index) {
    _videos = List.of(videos);
    _index = index;
    return _schedule();
  }

  Future<void> togglePause() {
    paused = !paused;
    if (paused) _pauseImmediately();
    return _schedule();
  }

  Future<void> toggleSound() async {
    final next = !muted;
    if (persistMuted != null && !await persistMuted!(next)) return;
    muted = next;
    return _schedule();
  }

  Future<void> lifecycle(bool active) {
    foreground = active;
    if (!active) _pauseImmediately();
    return _schedule();
  }

  void _pauseImmediately() {
    for (final c in controllers.values) {
      unawaited(c.pause().catchError((Object _) {}));
    }
  }

  Future<void> retry() async {
    final id = _videos[_index].id;
    errors.remove(id);
    // Dispose failed controllers inside the serialized queue.
    _queue = _queue.then((_) async {
      await controllers.remove(id)?.dispose();
    });
    await _schedule();
  }

  Future<void> _schedule() {
    _queue = _queue.then((_) => _sync()).catchError((Object _) {
      if (!_closed && _videos.isNotEmpty) {
        errors.add(_videos[_index].id);
        notifyListeners();
      }
    });
    return _queue;
  }

  Future<void> _sync() async {
    if (_closed) return;
    for (final c in controllers.values) {
      await c.pause();
    }
    final wanted = <String>{};
    if (_videos.isNotEmpty) {
      for (var i = _index - 1; i <= _index + 1; i++) {
        if (i >= 0 && i < _videos.length) wanted.add(_videos[i].id);
      }
    }
    for (final id in controllers.keys.toList()) {
      if (!wanted.contains(id)) {
        await controllers.remove(id)!.dispose();
        errors.remove(id);
      }
    }
    if (_videos.isEmpty) {
      await coordinateAudio?.call(false);
      if (_closed) return;
      notifyListeners();
      return;
    }
    final active = _videos[_index];
    await _prepare(active);
    if (_closed) return;
    // The target may have changed while initialization was pending.
    if (_videos.isNotEmpty && _videos[_index].id == active.id) {
      final c = controllers[active.id];
      if (c != null && c.value.isInitialized && !errors.contains(active.id)) {
        await coordinateAudio?.call(!muted && foreground && !paused);
        if (_closed) return;
        await c.setVolume(muted ? 0 : 1);
        if (!_closed &&
            foreground &&
            !paused &&
            _videos.isNotEmpty &&
            _videos[_index].id == active.id) {
          await c.play();
        }
      }
    }
    if (!_closed) notifyListeners();
    for (final video in List<VideoPost>.of(_videos)) {
      if (_closed) return;
      if (wanted.contains(video.id) && video.id != active.id) {
        await _prepare(video);
      }
    }
    if (!_closed) notifyListeners();
  }

  Future<void> _prepare(VideoPost video) async {
    if (controllers.containsKey(video.id) ||
        errors.contains(video.id) ||
        _closed) {
      return;
    }
    final c = createController(video);
    controllers[video.id] = c;
    try {
      await c.initialize().timeout(const Duration(seconds: 20));
      if (_closed) return;
      await c.setLooping(true);
      await c.setVolume(0);
    } catch (_) {
      errors.add(video.id);
    }
  }

  @override
  void dispose() {
    _closed = true;
    // Stop immediately; dispose after pending initialization/operations finish.
    for (final c in controllers.values) {
      unawaited(c.pause().catchError((Object _) {}));
    }
    unawaited(
      _queue.whenComplete(() async {
        for (final c in controllers.values) {
          await c.dispose();
        }
        controllers.clear();
      }),
    );
    super.dispose();
  }
}

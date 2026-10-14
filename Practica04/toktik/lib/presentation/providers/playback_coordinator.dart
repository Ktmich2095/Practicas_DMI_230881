import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/video_post.dart';

/// All player operations are serialized. Only the visible player may play.
class PlaybackCoordinator extends ChangeNotifier {
  final VideoPlayerController Function(VideoPost) createController;
  final Future<void> Function(bool audible)? coordinateAudio;
  final Future<bool> Function(bool muted)? persistMuted;
  final Future<void> Function(VideoPost)? onQualifiedView;
  final Duration initializationTimeout;
  PlaybackCoordinator({
    VideoPlayerController Function(VideoPost)? createController,
    this.coordinateAudio,
    this.persistMuted,
    this.onQualifiedView,
    this.initializationTimeout = const Duration(seconds: 60),
    bool initiallyMuted = true,
  }) : createController = createController ?? _defaultController {
    muted = initiallyMuted;
  }
  static VideoPlayerController _defaultController(VideoPost video) =>
      video.videoUrl.startsWith("https://")
      ? VideoPlayerController.networkUrl(Uri.parse(video.videoUrl))
      : VideoPlayerController.asset(video.videoUrl);
  final Map<String, VideoPlayerController> controllers = {};
  final Map<String, String> _controllerUrls = {};
  final Set<String> errors = {};
  List<VideoPost> _videos = [];
  int _index = 0;
  bool muted = true,
      paused = false,
      foreground = true,
      _closed = false,
      _introActive = false;
  Future<void> _queue = Future.value();
  Object? _owner;
  final Map<String, Duration> _watched = {};
  final Set<String> _counted = {};
  Duration? _lastPosition;
  String? _trackingId;
  bool _wasPlaying = false;
  Object claimFeed() => _owner = Object();
  void releaseFeed(Object owner) {
    if (identical(owner, _owner)) {
      _owner = null;
      unawaited(select(const [], 0));
    }
  }

  bool ownsFeed(Object owner) => identical(owner, _owner);
  void _observePlayback(VideoPost video, VideoPlayerController controller) {
    if (_closed || _videos.isEmpty || _videos[_index].id != video.id) return;
    final value = controller.value;
    final playing =
        foreground &&
        !paused &&
        !_introActive &&
        value.isInitialized &&
        value.isPlaying &&
        !value.isBuffering &&
        !value.hasError;
    if (_trackingId != video.id) {
      _trackingId = video.id;
      _lastPosition = null;
      _wasPlaying = false;
    }
    if (playing && _wasPlaying && _lastPosition != null) {
      final delta = value.position - _lastPosition!;
      // Sparse native callbacks can advance by more than a second. Count at
      // most one second per sample; unchanged positions and loop resets add none.
      if (delta > Duration.zero && delta <= value.duration) {
        final progress = delta > const Duration(seconds: 1)
            ? const Duration(seconds: 1)
            : delta;
        _watched[video.id] = (_watched[video.id] ?? Duration.zero) + progress;
        if (_watched[video.id]! >= const Duration(seconds: 3) &&
            _counted.add(video.id)) {
          unawaited(
            Future<void>.sync(() async {
              await onQualifiedView?.call(video);
            }).catchError((Object _) {
              // A failed restore did not record a view. Retry on later progress.
              _counted.remove(video.id);
            }),
          );
        }
      }
    }
    _lastPosition = value.position;
    _wasPlaying = playing;
  }

  VideoPlayerController? get current =>
      _videos.isEmpty ? null : controllers[_videos[_index].id];
  Future<void> select(List<VideoPost> videos, int index) {
    _lastPosition = null;
    _wasPlaying = false;
    _pauseImmediately();
    _videos = List.of(videos);
    _index = videos.isEmpty ? 0 : index.clamp(0, videos.length - 1);
    paused = false;
    return _schedule();
  }

  Future<void> updateVideos(List<VideoPost> videos, int index) {
    _pauseImmediately();
    _videos = List.of(videos);
    _index = videos.isEmpty ? 0 : index.clamp(0, videos.length - 1);
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

  Future<void> setIntroActive(bool active) {
    _introActive = active;
    if (active) _pauseImmediately();
    return _schedule();
  }

  void _pauseImmediately() {
    for (final c in controllers.values) {
      unawaited(c.pause().catchError((Object _) {}));
    }
  }

  Future<void> retry() async {
    if (_closed || _videos.isEmpty) return;
    final id = _videos[_index].id;
    errors.remove(id);
    // Dispose failed controllers inside the serialized queue.
    _queue = _queue.then((_) async {
      await controllers.remove(id)?.dispose();
      _controllerUrls.remove(id);
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
      final matching = _videos.where((video) => video.id == id);
      if (!wanted.contains(id) ||
          matching.isEmpty ||
          _controllerUrls[id] != matching.first.videoUrl) {
        await controllers.remove(id)!.dispose();
        _controllerUrls.remove(id);
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
    if (errors.contains(active.id)) {
      // Prioritize recovery of the visible player over preparing more decoders.
      await coordinateAudio?.call(false);
      if (!_closed) notifyListeners();
      return;
    }
    // The target may have changed while initialization was pending.
    if (_videos.isNotEmpty && _videos[_index].id == active.id) {
      final c = controllers[active.id];
      if (c != null && c.value.isInitialized && !errors.contains(active.id)) {
        await coordinateAudio?.call(
          !muted && foreground && !paused && !_introActive,
        );
        if (_closed) return;
        await c.setVolume(muted ? 0 : 1);
        if (!_closed &&
            foreground &&
            !paused &&
            !_introActive &&
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
    c.addListener(() => _observePlayback(video, c));
    controllers[video.id] = c;
    _controllerUrls[video.id] = video.videoUrl;
    final initialization = () async {
      await c.initialize();
      if (_closed) return;
      await c.setLooping(true);
      await c.setVolume(0);
    }();
    try {
      await initialization.timeout(initializationTimeout);
    } on TimeoutException {
      errors.add(video.id);
      // A timeout does not cancel the native decoder. Recover if it eventually
      // succeeds, but never revive a controller replaced by retry or a new URL.
      unawaited(
        initialization
            .then((_) async {
              if (!_closed && identical(controllers[video.id], c)) {
                errors.remove(video.id);
                await _schedule();
              }
            })
            .catchError((Object _) {}),
      );
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
        _controllerUrls.clear();
      }),
    );
    super.dispose();
  }
}

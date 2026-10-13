import 'package:flutter/foundation.dart';

import '../../domain/entities/video_post.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/entities/video_statistics.dart';
import '../../domain/repositories/video_statistics_repository.dart';
import '../../domain/repositories/video_catalog_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  final VideoCatalogRepository repository;
  final FavoritesRepository favoritesRepository;
  final VideoStatisticsRepository? statisticsRepository;
  DiscoverProvider({
    required this.repository,
    required this.favoritesRepository,
    this.statisticsRepository,
  });
  bool initialLoading = true,
      saving = false,
      loadingMore = false,
      hasMore = false;
  String? error, persistenceError;
  List<String> notices = [];
  List<VideoPost> videos = [];
  final Map<String, VideoPost> _favoriteVideos = {};
  Set<String> _favorites = {};
  VideoSource selectedSource = VideoSource.random,
      actualSource = VideoSource.random;
  int _page = 0, _generation = 0;
  bool _disposed = false, _restored = false;
  bool isFavorite(VideoPost video) => _favorites.contains(video.id);
  final Map<String, VideoStatistics> _statistics = {};
  Map<String, int> _viewIncrements = {};
  final Set<String> _viewedThisSession = {};
  Future<void> _viewWrites = Future.value();
  Future<void>? _restoring;
  List<VideoPost> _discoverVideos = [];
  VideoStatistics statistics(VideoPost video) => _statistics.putIfAbsent(
    VideoStatistics.key(video),
    () => VideoStatistics.resolve(video),
  );
  int likes(VideoPost video) =>
      statistics(video).likes + (isFavorite(video) ? 1 : 0);
  int views(VideoPost video) =>
      statistics(video).views +
      (_viewIncrements[VideoStatistics.key(video)] ?? 0);
  List<VideoPost> get discoverVideos => List.unmodifiable(_discoverVideos);
  void _prepareCatalog() {
    for (final video in [...videos, ..._favoriteVideos.values]) {
      statistics(video);
      if (_favorites.remove(video.videoUrl)) _favorites.add(video.id);
      if (isFavorite(video)) _favoriteVideos[video.id] = video;
    }
    final result = videos.toList()
      ..sort((a, b) => statistics(a).likes.compareTo(statistics(b).likes));
    if (result.length > 1 && listEquals(result, videos)) {
      result.add(result.removeAt(0));
    }
    _discoverVideos = result;
  }

  Future<void> _restore() async {
    try {
      _viewIncrements =
          await statisticsRepository?.readViewIncrements().timeout(
            const Duration(seconds: 5),
          ) ??
          {};
    } catch (_) {
      persistenceError = 'No se pudieron recuperar las visualizaciones.';
    }
    try {
      _favorites = await favoritesRepository.read().timeout(
        const Duration(seconds: 5),
      );
      for (final video in await favoritesRepository.readVideos().timeout(
        const Duration(seconds: 5),
      )) {
        _favoriteVideos[video.id] = video;
        statistics(video);
      }
    } catch (_) {
      persistenceError = 'No se pudieron recuperar los favoritos.';
    }
    _restored = true;
  }

  Future<void> recordView(VideoPost video) {
    final key = VideoStatistics.key(video);
    if (!_viewedThisSession.add(key)) return _viewWrites;
    _viewIncrements[key] = ((_viewIncrements[key] ?? 0) + 1).clamp(
      0,
      1000000000,
    );
    _emit();
    final snapshot = Map<String, int>.of(_viewIncrements);
    _viewWrites = _viewWrites.then((_) async {
      try {
        await statisticsRepository?.saveViewIncrements(snapshot);
      } catch (_) {
        persistenceError = 'No se pudieron guardar las visualizaciones.';
        _emit();
      }
    });
    return _viewWrites;
  }

  List<VideoPost> get favorites =>
      _favoriteVideos.values.where(isFavorite).toList();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> changeSource(VideoSource source) async {
    selectedSource = source;
    await loadNextPage();
  }

  Future<void> loadNextPage() async {
    final generation = ++_generation;
    initialLoading = true;
    loadingMore = false;
    error = null;
    notices = [];
    _emit();
    if (!_restored) {
      await (_restoring ??= _restore());
    }
    if (_disposed || generation != _generation) return;
    try {
      final batch = await repository.fetch(selectedSource);
      if (_disposed || generation != _generation) return;
      videos = batch.videos;
      _prepareCatalog();
      actualSource = batch.source;
      hasMore = batch.hasMore;
      _page = 0;
      notices = batch.notices;
      if (videos.isEmpty) {
        error = 'No hay contenido reproducible. Cambia de fuente o reintenta.';
      }
    } catch (_) {
      if (generation == _generation) {
        error = 'No pudimos cargar el contenido. Intenta nuevamente.';
      }
    }
    if (generation != _generation) return;
    initialLoading = false;
    _emit();
  }

  Future<void> loadMore() async {
    if (!hasMore || initialLoading || loadingMore) return;
    final generation = _generation;
    loadingMore = true;
    _emit();
    try {
      final batch = await repository.fetch(actualSource, page: _page + 1);
      if (_disposed || generation != _generation) return;
      if (batch.source != actualSource) {
        hasMore = false;
        notices = [
          ...notices,
          ...batch.notices,
          'Fin de la fuente actual. Cambia de fuente para continuar.',
        ];
      } else {
        final ids = videos.map((v) => v.id).toSet();
        videos = [...videos, ...batch.videos.where((v) => ids.add(v.id))];
        _prepareCatalog();
        hasMore = batch.hasMore && batch.videos.isNotEmpty;
        _page++;
      }
    } catch (_) {
      notices = [...notices, 'No se pudo cargar la siguiente página.'];
    }
    if (generation == _generation) {
      loadingMore = false;
      _emit();
    }
  }

  Future<void> toggleFavorite(VideoPost video) async {
    if (saving) return;
    saving = true;
    persistenceError = null;
    final before = Set<String>.of(_favorites);
    final catalogBefore = Map<String, VideoPost>.of(_favoriteVideos);
    if (!_favorites.remove(video.id)) {
      _favorites.add(video.id);
      _favoriteVideos[video.id] = video;
    } else {
      _favoriteVideos.remove(video.id);
    }
    _emit();
    try {
      await favoritesRepository.saveVideos(favorites);
    } catch (_) {
      _favorites = before;
      _favoriteVideos
        ..clear()
        ..addAll(catalogBefore);
      persistenceError = 'No se pudo guardar el favorito. Intenta nuevamente.';
    }
    saving = false;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

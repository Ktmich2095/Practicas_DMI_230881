import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nowPlayingMoviesProvider =
    StateNotifierProvider<MoviesNotifier, List<Movie>>((ref) {
      final fetchMoreMovies = ref.watch(movieRepositoryProvider).getNowPlaying;

      return MoviesNotifier(fetchMoreMovies: fetchMoreMovies);
    });

typedef MovieCallback = Future<List<Movie>> Function({int page});

class MoviesNotifier extends StateNotifier<List<Movie>> {
  int currentPage = 0;
  MovieCallback fetchMoreMovies;

  MoviesNotifier({required this.fetchMoreMovies}) : super([]);

  bool isLoading = false;

  Future<void> loadNextPage() async {
    if (isLoading) return;
    isLoading = true;
    try {
      final nextPage = currentPage + 1;
      final movies = await fetchMoreMovies(page: nextPage);
      if (!mounted) return;
      currentPage = nextPage;
      state = [...state, ...movies];
    } finally {
      isLoading = false;
    }
  }
}

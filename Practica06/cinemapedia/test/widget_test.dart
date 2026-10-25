import 'dart:async';

import 'package:cinemapedia/domain/datasources/movies_datasource.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:cinemapedia/infrastructure/repositories/movie_repository_impl.dart';
import 'package:cinemapedia/main.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_repository_provider.dart';
import 'package:cinemapedia/presentation/screens/movies/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Movie movie(String title) => Movie(
  adult: false,
  backdropPath: '',
  genreIds: [],
  id: 1,
  originalLanguage: 'es',
  originalTitle: title,
  overview: '',
  popularity: 1,
  posterPath: '',
  releaseDate: DateTime(2026),
  title: title,
  video: false,
  voteAverage: 8,
  voteCount: 1,
);

class FakeDatasource extends MoviesDatasource {
  final Future<List<Movie>> Function(int) fetch;
  FakeDatasource(this.fetch);
  @override
  Future<List<Movie>> getNowPlaying({int page = 1}) => fetch(page);
}

void main() {
  testWidgets(
    'Real app router starts inside ProviderScope and renders movies',
    (tester) async {
      final response = Completer<List<Movie>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(
              MovieRepositoryImpl(FakeDatasource((_) => response.future)),
            ),
          ],
          child: const MainApp(),
        ),
      );
      await tester.pump();
      expect(find.text('Cinemapedia'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete([movie('Película de prueba')]);
      await tester.pumpAndSettle();
      expect(find.text('Película de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failed initial request shows retry and retries the same page', (
    tester,
  ) async {
    final pages = <int>[];
    final source = FakeDatasource((page) async {
      pages.add(page);
      if (pages.length == 1) throw StateError('offline');
      return [movie('Recuperada')];
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            MovieRepositoryImpl(source),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar las películas.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperada'), findsOneWidget);
    expect(pages, [1, 1]);
    await tester.tap(find.text('Cargar más'));
    await tester.pumpAndSettle();
    expect(pages, [1, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  test(
    'Notifier prevents overlapping pages and appends successful data',
    () async {
      final response = Completer<List<Movie>>();
      var calls = 0;
      final notifier = MoviesNotifier(
        fetchMoreMovies: ({page = 1}) {
          calls++;
          return response.future;
        },
      );
      addTearDown(notifier.dispose);
      final first = notifier.loadNextPage();
      await notifier.loadNextPage();
      expect(calls, 1);
      expect(notifier.currentPage, 0);
      response.complete([movie('Primera')]);
      await first;
      expect(notifier.currentPage, 1);
      expect(notifier.state.single.title, 'Primera');
    },
  );

  test(
    'Disposed notifier does not update state after an async response',
    () async {
      final response = Completer<List<Movie>>();
      final notifier = MoviesNotifier(
        fetchMoreMovies: ({page = 1}) => response.future,
      );
      final pending = notifier.loadNextPage();
      notifier.dispose();
      response.complete([movie('Tardía')]);
      await expectLater(pending, completes);
    },
  );
}

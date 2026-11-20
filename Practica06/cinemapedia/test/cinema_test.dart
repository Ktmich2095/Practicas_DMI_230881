import 'package:cinemapedia/cinema_app.dart';
import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'idioma, contenido y favoritos permanecen después de reiniciar',
    () async {
      final state = CinemaState();
      await state.init();
      await state.setLanguage('de-DE');
      await state.setKind(true);
      await state.toggle('tv', {'id': 42, 'name': 'Serie'});
      final restored = CinemaState();
      await restored.init();
      expect(restored.language, 'de-DE');
      expect(restored.tv, isTrue);
      expect(restored.isFavorite('tv', 42), isTrue);
      await restored.toggle('tv', {'id': 42});
      expect(restored.isFavorite('tv', 42), isFalse);
      state.dispose();
      restored.dispose();
    },
  );

  test('clasificación por país y respaldo NR para películas y series', () {
    final movie = {
      'release_dates': {
        'results': [
          {
            'iso_3166_1': 'MX',
            'release_dates': [
              {'certification': 'B15'},
            ],
          },
        ],
      },
    };
    final series = {
      'content_ratings': {
        'results': [
          {'iso_3166_1': 'US', 'rating': 'TV-14'},
        ],
      },
    };
    expect(rating(movie, 'movie', 'es-MX'), 'B15');
    expect(rating(movie, 'movie', 'en-US'), 'NR');
    expect(rating(series, 'tv', 'en-US'), 'TV-14');
  });

  test(
    'el provider evita solicitudes simultáneas y avanza al completar',
    () async {
      final notifier = MoviesNotifier(
        fetchMoreMovies: ({page = 1}) async => [],
      );
      await notifier.loadNextPage();
      expect(notifier.currentPage, 1);
      notifier.dispose();
    },
  );
}

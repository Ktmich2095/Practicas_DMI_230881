import 'package:cinemapedia/presentation/providers/movies/movies_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'home-screen';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cinemapedia')),
    body: const SafeArea(child: _HomeView()),
  );
}

class _HomeView extends ConsumerStatefulWidget {
  const _HomeView();
  @override
  ConsumerState<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<_HomeView> {
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      await ref.read(nowPlayingMoviesProvider.notifier).loadNextPage();
    } catch (_) {
      // Do not show HTTP diagnostics that could contain API credentials.
      if (mounted) setState(() => hasError = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(nowPlayingMoviesProvider);
    if (isLoading && movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (movies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hasError ? Icons.wifi_off : Icons.movie_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                hasError
                    ? 'No se pudieron cargar las películas.'
                    : 'No hay películas disponibles.',
                textAlign: TextAlign.center,
              ),
              if (hasError)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Comprueba tu conexión y vuelve a intentarlo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton(
                onPressed: loadMovies,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: movies.length + 1,
      itemBuilder: (context, index) {
        if (index < movies.length) {
          return ListTile(title: Text(movies[index].title));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (hasError)
                const Text('No se pudo cargar la siguiente página.'),
              if (isLoading)
                const CircularProgressIndicator()
              else
                FilledButton.tonal(
                  onPressed: loadMovies,
                  child: Text(hasError ? 'Reintentar' : 'Cargar más'),
                ),
            ],
          ),
        );
      },
    );
  }
}

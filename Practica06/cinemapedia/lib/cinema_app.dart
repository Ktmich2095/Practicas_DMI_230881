import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const langs = ['es-MX', 'en-US', 'de-DE', 'zh-CN', 'ar-SA'];
const langNames = ['Español', 'English', 'Deutsch', '中文', 'العربية'];
const words = <String, List<String>>{
  'home': ['Inicio', 'Home', 'Start', '首页', 'الرئيسية'],
  'popular': ['Populares', 'Popular', 'Beliebt', '热门', 'الأكثر شعبية'],
  'favorites': ['Favoritos', 'Favorites', 'Favoriten', '收藏', 'المفضلة'],
  'settings': ['Configuración', 'Settings', 'Einstellungen', '设置', 'الإعدادات'],
  'content': ['Contenido', 'Content', 'Inhalt', '内容', 'المحتوى'],
  'language': ['Idioma', 'Language', 'Sprache', '语言', 'اللغة'],
  'movies': ['Películas', 'Movies', 'Filme', '电影', 'أفلام'],
  'series': ['Series', 'Series', 'Serien', '剧集', 'مسلسلات'],
  'now': ['En cines', 'Now playing', 'Im Kino', '正在热映', 'في السينما'],
  'upcoming': ['Próximamente', 'Coming soon', 'Demnächst', '即将上映', 'قريباً'],
  'top': [
    'Mejor calificadas',
    'Top rated',
    'Bestbewertet',
    '评分最高',
    'الأعلى تقييماً',
  ],
  'search': ['Buscar', 'Search', 'Suchen', '搜索', 'بحث'],
  'empty': [
    'Aún no tienes favoritos',
    'No favorites yet',
    'Noch keine Favoriten',
    '暂无收藏',
    'لا توجد مفضلات بعد',
  ],
  'retry': ['Reintentar', 'Retry', 'Erneut versuchen', '重试', 'إعادة المحاولة'],
  'error': [
    'No se pudo cargar el contenido',
    'Could not load content',
    'Inhalt konnte nicht geladen werden',
    '无法加载内容',
    'تعذر تحميل المحتوى',
  ],
  'cast': ['Reparto', 'Cast', 'Besetzung', '演员', 'طاقم التمثيل'],
  'trailer': ['Tráiler', 'Trailer', 'Trailer', '预告片', 'الإعلان'],
  'similar': ['Similares', 'Similar', 'Ähnlich', '相似', 'مشابه'],
  'noTrailer': [
    'Tráiler no disponible',
    'Trailer unavailable',
    'Trailer nicht verfügbar',
    '暂无预告片',
    'الإعلان غير متاح',
  ],
  'overview': [
    'Sin sinopsis disponible',
    'No overview available',
    'Keine Inhaltsangabe verfügbar',
    '暂无简介',
    'لا يوجد ملخص',
  ],
  'loading': ['Cargando', 'Loading', 'Laden', '加载中', 'جار التحميل'],
  'date': ['Estreno', 'Release', 'Veröffentlichung', '上映', 'تاريخ الإصدار'],
};
String tr(String key, String lang) =>
    (words[key] ?? [key, key, key, key, key])[max(0, langs.indexOf(lang))];
String img(String? path, {String size = 'w500'}) =>
    path == null || path.isEmpty ? '' : 'https://image.tmdb.org/t/p/$size$path';

class CinemaState extends ChangeNotifier {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  String language = 'es-MX';
  bool tv = false;
  bool ready = false;
  Map<String, Map<String, dynamic>> favorites = {};
  String get kind => tv ? 'tv' : 'movie';
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    language = p.getString('language') ?? 'es-MX';
    if (!langs.contains(language)) language = 'es-MX';
    tv = p.getBool('tv') ?? false;
    final data = p.getString('favorites');
    if (data != null) {
      try {
        final m = jsonDecode(data) as Map<String, dynamic>;
        favorites = m.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
      } catch (_) {}
    }
    ready = true;
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    language = v;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString('language', v);
  }

  Future<void> setKind(bool v) async {
    tv = v;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool('tv', v);
  }

  String key(String type, dynamic id) => '$type:$id';
  bool isFavorite(String type, dynamic id) =>
      favorites.containsKey(key(type, id));
  Future<void> toggle(String type, Map<String, dynamic> item) async {
    final k = key(type, item['id']);
    if (favorites.containsKey(k)) {
      favorites.remove(k);
    } else {
      favorites[k] = item;
    }
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'favorites',
      jsonEncode(favorites),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic> params = const {},
    String? locale,
  }) async {
    final response = await dio.get(
      path,
      queryParameters: {
        'api_key': dotenv.env['THE_MOVIEDB_KEY'] ?? dotenv.env['API_KEY_MOVIEBD'] ?? '',
        'language': locale ?? language,
        ...params,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> list(
    String path, {
    int page = 1,
    Map<String, dynamic> params = const {},
  }) async {
    final data = await get(path, params: {'page': page, ...params});
    return (data['results'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> detail(String type, int id) async {
    final data = await get(
      '/$type/$id',
      params: {
        'append_to_response':
            'credits,videos,${type == 'movie' ? 'release_dates' : 'content_ratings'}',
      },
    );
    if (language != 'en-US' &&
        (data['overview'] as String? ?? '').trim().isEmpty) {
      try {
        final en = await get('/$type/$id', locale: 'en-US');
        data['overview'] = en['overview'];
      } catch (_) {}
    }
    return data;
  }
}

final cinema = CinemaState();
String title(Map<String, dynamic> m) =>
    (m['title'] ?? m['name'] ?? m['original_title'] ?? m['original_name'] ?? '')
        as String;

class CinemaApp extends StatefulWidget {
  const CinemaApp({super.key});
  @override
  State<CinemaApp> createState() => _CinemaAppState();
}

class _CinemaAppState extends State<CinemaApp> {
  @override
  void initState() {
    super.initState();
    cinema.addListener(update);
    cinema.init();
  }

  void update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cinema.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Cinemapedia',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6f55e8),
        brightness: Brightness.dark,
      ),
    ),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.ltr, child: child!),
    home: const Splash(),
  );
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool elapsed = false;
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cinema.removeListener(refresh);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    cinema.addListener(refresh);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => elapsed = true);
    });
  }

  @override
  Widget build(BuildContext c) {
    if (elapsed && cinema.ready) return const Shell();
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 76,
              color: Colors.deepPurpleAccent,
            ),
            SizedBox(height: 18),
            Text(
              'CINEMAPEDIA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cinema.addListener(refresh);
  }

  @override
  void dispose() {
    cinema.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = cinema.language;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinemapedia'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Center(child: Icon(Icons.movie_filter, size: 72)),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(tr('settings', l)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: tab,
        children: [
          HomePage(key: ValueKey('home-${cinema.kind}-$l')),
          PopularPage(key: ValueKey('popular-${cinema.kind}-$l')),
          FavoritesPage(key: ValueKey('favorites-${cinema.kind}-$l')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr('home', l),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_fire_department_outlined),
            selectedIcon: const Icon(Icons.local_fire_department),
            label: tr('popular', l),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: tr('favorites', l),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cinema.addListener(refresh);
  }

  @override
  void dispose() {
    cinema.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final l = cinema.language;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings', l))),
      body: ListView(
        children: [
          ListTile(
            title: Text(tr('content', l)),
            leading: const Icon(Icons.video_library),
          ),
          RadioGroup<bool>(
            groupValue: cinema.tv,
            onChanged: (v) {
              if (v != null) cinema.setKind(v);
            },
            child: Column(
              children: [
                RadioListTile(value: false, title: Text(tr('movies', l))),
                RadioListTile(value: true, title: Text(tr('series', l))),
              ],
            ),
          ),
          ListTile(
            title: Text(tr('language', l)),
            leading: const Icon(Icons.language),
          ),
          RadioGroup<String>(
            groupValue: l,
            onChanged: (v) {
              if (v != null) cinema.setLanguage(v);
            },
            child: Column(
              children: [
                for (var i = 0; i < langs.length; i++)
                  RadioListTile(value: langs[i], title: Text(langNames[i])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openDetail(BuildContext c, Map<String, dynamic> m, {String? type}) {
  Navigator.push(
    c,
    MaterialPageRoute(
      builder: (_) => DetailPage(type: type ?? cinema.kind, id: m['id'] as int),
    ),
  );
}

class Poster extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? type;
  const Poster(this.item, {super.key, this.type});
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: () => openDetail(c, item, type: type),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: RemotePoster(img(item['poster_path'] as String?)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class RemotePoster extends StatelessWidget {
  final String url;
  const RemotePoster(this.url, {super.key});
  @override
  Widget build(BuildContext c) => Container(
    color: Colors.white10,
    width: double.infinity,
    child: url.isEmpty
        ? const Icon(Icons.movie_outlined, size: 40)
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined),
          ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c) {
    final type = cinema.kind;
    return ListView(
      children: [
        FeaturedCarousel(key: ValueKey('$type-${cinema.language}'), type: type),
        MovieRow(
          label: tr('now', cinema.language),
          path: '/$type/${type == 'movie' ? 'now_playing' : 'on_the_air'}',
        ),
        MovieRow(
          label: tr('upcoming', cinema.language),
          path: '/$type/${type == 'movie' ? 'upcoming' : 'airing_today'}',
        ),
        MovieRow(label: tr('top', cinema.language), path: '/$type/top_rated'),
      ],
    );
  }
}

class FeaturedCarousel extends StatefulWidget {
  final String type;
  const FeaturedCarousel({super.key, required this.type});
  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final pc = PageController();
  List<Map<String, dynamic>> items = [];
  int index = 0;
  Timer? timer;
  bool error = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await cinema.list(
        '/${widget.type}/${widget.type == 'movie' ? 'now_playing' : 'on_the_air'}',
      );
      if (!mounted) return;
      setState(() {
        items = r.take(8).toList();
        error = false;
      });
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (items.isNotEmpty && pc.hasClients) {
          final next = (index + 1) % items.length;
          pc.animateToPage(
            next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => error = true);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    super.dispose();
  }

  void move(int d) {
    if (items.isNotEmpty) {
      pc.animateToPage(
        (index + d + items.length) % items.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    if (items.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: error
              ? TextButton(
                  onPressed: load,
                  child: Text(tr('retry', cinema.language)),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: pc,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (c, i) {
              final m = items[i];
              return InkWell(
                onTap: () => openDetail(c, m, type: widget.type),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RemotePoster(
                      img(m['backdrop_path'] as String?, size: 'w780'),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 45,
                      right: 45,
                      bottom: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title(m),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            (m['overview'] as String? ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.filledTonal(
              onPressed: () => move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filledTonal(
              onPressed: () => move(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MovieRow extends StatefulWidget {
  final String label, path;
  const MovieRow({super.key, required this.label, required this.path});
  @override
  State<MovieRow> createState() => _MovieRowState();
}

class _MovieRowState extends State<MovieRow> {
  final scroll = ScrollController();
  List<Map<String, dynamic>> items = [];
  int page = 0;
  bool loading = false, error = false, end = false;
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 350) load();
    });
    load();
  }

  Future<void> load() async {
    if (loading || end) return;
    setState(() {
      loading = true;
      error = false;
    });
    try {
      final r = await cinema.list(widget.path, page: page + 1);
      if (!mounted) return;
      setState(() {
        page++;
        end = r.isEmpty;
        final ids = items.map((e) => e['id']).toSet();
        items.addAll(r.where((e) => ids.add(e['id'])));
      });
    } catch (_) {
      if (mounted) setState(() => error = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(widget.label, style: Theme.of(c).textTheme.titleLarge),
      ),
      SizedBox(
        height: 240,
        child: items.isEmpty
            ? Center(
                child: error
                    ? TextButton(
                        onPressed: load,
                        child: Text(tr('retry', cinema.language)),
                      )
                    : const CircularProgressIndicator(),
              )
            : ListView.builder(
                controller: scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length + 1,
                itemBuilder: (c, i) => i == items.length
                    ? SizedBox(
                        width: 80,
                        child: Center(
                          child: error
                              ? IconButton(
                                  onPressed: load,
                                  icon: const Icon(Icons.refresh),
                                )
                              : loading
                              ? const CircularProgressIndicator()
                              : const SizedBox(),
                        ),
                      )
                    : SizedBox(
                        width: 135,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Poster(items[i]),
                        ),
                      ),
              ),
      ),
    ],
  );
}

class PopularPage extends StatefulWidget {
  const PopularPage({super.key});
  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> {
  final scroll = ScrollController();
  List<Map<String, dynamic>> items = [];
  int page = 0;
  bool loading = false, error = false, end = false;
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 700) load();
    });
    load();
  }

  Future<void> load() async {
    if (loading || end) return;
    setState(() {
      loading = true;
      error = false;
    });
    try {
      final r = await cinema.list('/${cinema.kind}/popular', page: page + 1);
      if (!mounted) return;
      setState(() {
        page++;
        end = r.isEmpty;
        final ids = items.map((e) => e['id']).toSet();
        items.addAll(r.where((e) => ids.add(e['id'])));
      });
    } catch (_) {
      if (mounted) setState(() => error = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    if (items.isEmpty) {
      return Center(
        child: error
            ? TextButton(
                onPressed: load,
                child: Text(tr('retry', cinema.language)),
              )
            : const CircularProgressIndicator(),
      );
    }
    return CustomScrollView(
      controller: scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childCount: items.length,
            itemBuilder: (c, i) =>
                SizedBox(height: 215 + (i % 3) * 20, child: Poster(items[i])),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: error
                ? TextButton(
                    onPressed: load,
                    child: Text(tr('retry', cinema.language)),
                  )
                : loading
                ? const CircularProgressIndicator()
                : const SizedBox(height: 20),
          ),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext c) {
    final items = cinema.favorites.entries
        .where((e) => e.key.startsWith('${cinema.kind}:'))
        .map((e) => e.value)
        .toList();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 64),
            const SizedBox(height: 16),
            Text(tr('empty', cinema.language)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              ),
              icon: const Icon(Icons.search),
              label: Text(tr('search', cinema.language)),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: .53,
      ),
      itemCount: items.length,
      itemBuilder: (c, i) => FavoritePoster(
        key: ValueKey("${cinema.kind}:${items[i]['id']}:${cinema.language}"),
        item: items[i],
        type: cinema.kind,
      ),
    );
  }
}

class FavoritePoster extends StatefulWidget {
  final Map<String, dynamic> item;
  final String type;
  const FavoritePoster({super.key, required this.item, required this.type});
  @override
  State<FavoritePoster> createState() => _FavoritePosterState();
}

class _FavoritePosterState extends State<FavoritePoster> {
  late Future<Map<String, dynamic>> translated;
  @override
  void initState() {
    super.initState();
    translated = cinema.get('/${widget.type}/${widget.item['id']}');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: translated,
    builder: (context, snapshot) =>
        Poster(snapshot.data ?? widget.item, type: widget.type),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Timer? timer;
  int generation = 0;
  List<Map<String, dynamic>> results = [];
  bool loading = false, error = false;
  void search(String q) {
    timer?.cancel();
    final g = ++generation;
    if (q.trim().isEmpty) {
      setState(() {
        results = [];
        loading = false;
      });
      return;
    }
    setState(() {
      loading = true;
      error = false;
    });
    timer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await cinema.list(
          '/search/${cinema.kind}',
          params: {'query': q},
        );
        if (mounted && g == generation) setState(() => results = r);
      } catch (_) {
        if (mounted && g == generation) setState(() => error = true);
      } finally {
        if (mounted && g == generation) setState(() => loading = false);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: TextField(
        autofocus: true,
        onChanged: search,
        decoration: InputDecoration(
          hintText: tr('search', cinema.language),
          border: InputBorder.none,
        ),
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error
        ? Center(child: Text(tr('error', cinema.language)))
        : ListView.builder(
            itemCount: results.length,
            itemBuilder: (c, i) {
              final m = results[i];
              return ListTile(
                leading: SizedBox(
                  width: 45,
                  child: RemotePoster(img(m['poster_path'] as String?)),
                ),
                title: Text(title(m)),
                onTap: () => openDetail(c, m),
              );
            },
          ),
  );
}

String rating(Map<String, dynamic> data, String type, String language) {
  final country = language.split('-').last;
  final block = type == 'movie'
      ? data['release_dates']
      : data['content_ratings'];
  final rows = (block is Map ? block['results'] : null) as List? ?? [];
  for (final row in rows) {
    if (row['iso_3166_1'] != country) continue;
    if (type == 'tv') {
      final value = row['rating'] as String? ?? '';
      if (value.isNotEmpty) return value;
    } else {
      for (final entry in (row['release_dates'] as List? ?? [])) {
        final value = entry['certification'] as String? ?? '';
        if (value.isNotEmpty) return value;
      }
    }
  }
  return 'NR';
}

class DetailPage extends StatefulWidget {
  final String type;
  final int id;
  const DetailPage({super.key, required this.type, required this.id});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() {
    super.initState();
    future = cinema.detail(widget.type, widget.id);
  }

  @override
  Widget build(BuildContext c) {
    final l = cinema.language;
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemapedia')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (c, s) {
          if (s.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('error', l)),
                  TextButton(
                    onPressed: () => setState(
                      () => future = cinema.detail(widget.type, widget.id),
                    ),
                    child: Text(tr('retry', l)),
                  ),
                ],
              ),
            );
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = s.data!;
          final credits = (m['credits'] as Map?)?['cast'] as List? ?? [];
          final videos = (m['videos'] as Map?)?['results'] as List? ?? [];
          final trailers = videos
              .where(
                (v) =>
                    v['site'] == 'YouTube' &&
                    (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
              )
              .toList();
          final genres = (m['genres'] as List? ?? [])
              .map((e) => e['name'])
              .join(' · ');
          final date = m['release_date'] ?? m['first_air_date'] ?? '';
          return ListView(
            children: [
              SizedBox(
                height: 260,
                child: RemotePoster(
                  img(m['backdrop_path'] as String?, size: 'w780'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 105,
                          height: 155,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RemotePoster(
                              img(m['poster_path'] as String?),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title(m),
                                style: Theme.of(c).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(genres),
                              const SizedBox(height: 8),
                              Text('${tr('date', l)}: $date'),
                              const SizedBox(height: 6),
                              Chip(label: Text(rating(m, widget.type, l))),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: cinema,
                          builder: (_, _) => IconButton(
                            onPressed: () => cinema.toggle(widget.type, m),
                            icon: Icon(
                              cinema.isFavorite(widget.type, widget.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      (m['overview'] as String? ?? '').isEmpty
                          ? tr('overview', l)
                          : m['overview'],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('cast', l),
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 145,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: min(15, credits.length),
                        itemBuilder: (c, i) {
                          final actor = credits[i];
                          return SizedBox(
                            width: 90,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage:
                                      (actor['profile_path'] as String?) != null
                                      ? NetworkImage(
                                          img(actor['profile_path'] as String?),
                                        )
                                      : null,
                                  child: actor['profile_path'] == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  actor['name'] ?? '',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      tr('trailer', l),
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (trailers.isEmpty)
                      Text(tr('noTrailer', l))
                    else
                      TrailerPlayer(
                        key: ValueKey(trailers.first['key']),
                        videoId: trailers.first['key'] as String,
                      ),
                  ],
                ),
              ),
              MovieRow(
                label: tr('similar', l),
                path: '/${widget.type}/${widget.id}/similar',
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class TrailerPlayer extends StatefulWidget {
  final String videoId;
  const TrailerPlayer({super.key, required this.videoId});
  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  late YoutubePlayerController controller;
  @override
  void initState() {
    super.initState();
    controller = YoutubePlayerController.fromVideoId(videoId: widget.videoId);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => YoutubePlayer(controller: controller);
}


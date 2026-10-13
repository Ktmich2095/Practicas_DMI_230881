import 'dart:convert';

import '../storage/preferences_store.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../../domain/entities/video_post.dart';
import '../mappers/video_mapper.dart';

class PreferencesFavoritesRepository implements FavoritesRepository {
  final PreferencesStore preferences;
  PreferencesFavoritesRepository({PreferencesStore? storage})
    : preferences = storage ?? SharedPreferencesStore();
  @override
  Future<Set<String>> read() async {
    if (await preferences.getString('toktik.favorite_catalog.v2') != null) {
      return (await readVideos()).map((v) => v.id).toSet();
    }
    final videos = await readVideos();
    return {
      ...videos.map((v) => v.id),
      ...(await preferences.getStringList('toktik.favorites.v1') ?? []),
    };
  }

  @override
  Future<void> save(Set<String> ids) =>
      preferences.setStringList('toktik.favorites.v1', ids.toList());
  @override
  Future<List<VideoPost>> readVideos() async {
    final raw = await preferences.getString('toktik.favorite_catalog.v2');
    if (raw == null) return [];
    return VideoMapper.maps(jsonDecode(raw)).map(VideoMapper.fromJson).toList();
  }

  @override
  Future<void> saveVideos(List<VideoPost> videos) async {
    // A single JSON write stores the favorite and its like together.
    await preferences.setString(
      'toktik.favorite_catalog.v2',
      jsonEncode(videos.map(VideoMapper.toJson).toList()),
    );
    // v2 is authoritative when present, including an empty list.
  }
}

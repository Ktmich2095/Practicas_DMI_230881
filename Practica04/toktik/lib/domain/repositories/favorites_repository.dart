import '../entities/video_post.dart';

abstract class FavoritesRepository {
  Future<Set<String>> read();
  Future<void> save(Set<String> ids);
  Future<List<VideoPost>> readVideos() async => [];
  Future<void> saveVideos(List<VideoPost> videos) =>
      save(videos.map((v) => v.id).toSet());
}

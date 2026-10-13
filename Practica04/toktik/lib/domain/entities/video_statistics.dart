import 'video_post.dart';

/// Stable demonstration metrics, never presented as external platform data.
class VideoStatistics {
  final int likes, views;
  final bool simulatedLikes, simulatedViews;
  const VideoStatistics(
    this.likes,
    this.views,
    this.simulatedLikes,
    this.simulatedViews,
  );
  static String key(VideoPost video) => '${video.origin.name}:${video.id}';
  static VideoStatistics resolve(VideoPost video) {
    var hash = 2166136261;
    for (final unit in key(video).codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xffffffff;
    }
    final likes = video.likes > 0
        ? video.likes.clamp(1, 100000000000)
        : 850 + hash % 450000;
    final views = video.views > likes
        ? video.views.clamp(likes + 1, 10000000000000)
        : likes * (8 + hash % 13) + 100;
    return VideoStatistics(
      likes,
      views,
      video.likes <= 0,
      video.views <= likes,
    );
  }
}

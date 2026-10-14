import 'video_post.dart';
import 'video_source.dart';

class VideoBatch {
  final List<VideoPost> videos;
  final VideoSource source;
  final bool hasMore;
  final List<String> notices;
  const VideoBatch({
    required this.videos,
    required this.source,
    this.hasMore = false,
    this.notices = const [],
  });
}

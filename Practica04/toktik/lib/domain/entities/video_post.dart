import 'video_source.dart';

class VideoPost {
  final String caption, videoUrl, creator, source;
  final String? providerId, sourcePage, license;
  final VideoSource origin;
  final int? width, height;
  final int likes, views;
  String get id {
    final raw = providerId ?? videoUrl;
    return origin == VideoSource.local || raw.startsWith('${origin.name}:')
        ? raw
        : '${origin.name}:$raw';
  }

  const VideoPost({
    required this.caption,
    required this.videoUrl,
    this.creator = 'TokTik Studio',
    this.source = 'Archivo local',
    this.likes = 0,
    this.views = 0,
    this.providerId,
    this.sourcePage,
    this.license,
    this.origin = VideoSource.local,
    this.width,
    this.height,
  });
}

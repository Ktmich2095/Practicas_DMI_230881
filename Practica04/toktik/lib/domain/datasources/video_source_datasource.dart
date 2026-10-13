import '../entities/video_batch.dart';
import '../entities/video_source.dart';

abstract class VideoSourceDatasource {
  VideoSource get source;
  bool get available;
  Future<VideoBatch> fetch(int page);
}

class SourceException implements Exception {
  final String message;
  const SourceException(this.message);
  @override
  String toString() => message;
}

import '../entities/video_batch.dart';
import '../entities/video_source.dart';

abstract class VideoSourceDatasource {
  VideoSource get source;
  bool get available;
  Future<VideoBatch> fetch(int page);
}

class SourceException implements Exception {
  final String message;
  final String code;
  final int? httpStatus;
  const SourceException(this.message, {this.code = 'source', this.httpStatus});
  @override
  String toString() => message;
}

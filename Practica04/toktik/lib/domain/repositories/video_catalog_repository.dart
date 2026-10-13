import '../entities/video_batch.dart';
import '../entities/video_source.dart';

abstract class VideoCatalogRepository {
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0});
}

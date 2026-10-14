import '../../domain/entities/video_post.dart';
import '../../config/api/api_config.dart';
import '../../domain/datasources/video_source_datasource.dart';
import '../../domain/entities/video_batch.dart';
import '../../domain/entities/video_source.dart';
import '../mappers/video_mapper.dart';
import 'json_api_client.dart';

class PixabayDatasource implements VideoSourceDatasource {
  final JsonApiClient api;
  final String key;
  PixabayDatasource(this.api, {this.key = ApiConfig.pixabayKey});
  @override
  VideoSource get source => VideoSource.pixabay;
  @override
  bool get available => key.trim().isNotEmpty;
  @override
  Future<VideoBatch> fetch(int page) async {
    if (!available) throw const SourceException('Falta PIXABAY_API_KEY');
    final data = await api.get(
      Uri.https('pixabay.com', '/api/videos/', {
        'key': key,
        'page': '${page + 1}',
        'per_page': '${ApiConfig.pageSize}',
        'safesearch': 'true',
        'order': 'popular',
      }),
    );
    return VideoBatch(
      source: source,
      videos: VideoMapper.maps(data['hits'])
          .map(VideoMapper.pixabay)
          .whereType<VideoPost>()
          .toList(),
      hasMore:
          (page + 1) * ApiConfig.pageSize <
          VideoMapper.number(data['totalHits']),
    );
  }
}

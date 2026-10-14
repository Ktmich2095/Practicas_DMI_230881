import '../../domain/entities/video_post.dart';
import '../../config/api/api_config.dart';
import '../../domain/datasources/video_source_datasource.dart';
import '../../domain/entities/video_batch.dart';
import '../../domain/entities/video_source.dart';
import '../mappers/video_mapper.dart';
import 'json_api_client.dart';

class CoverrDatasource implements VideoSourceDatasource {
  final JsonApiClient api;
  final String key;
  CoverrDatasource(this.api, {this.key = ApiConfig.coverrKey});
  @override
  VideoSource get source => VideoSource.coverr;
  @override
  bool get available => key.trim().isNotEmpty;
  @override
  Future<VideoBatch> fetch(int page) async {
    if (!available) throw const SourceException('Falta COVERR_API_KEY');
    final data = await api.get(
      Uri.https('api.coverr.co', '/videos', {
        'page': '$page',
        'page_size': '${ApiConfig.pageSize}',
        'urls': 'true',
        'sort': 'popular',
      }),
      headers: {'Authorization': 'Bearer $key'},
    );
    return VideoBatch(
      source: source,
      videos: VideoMapper.maps(data['hits'])
          .map(VideoMapper.coverr)
          .whereType<VideoPost>()
          .toList(),
      hasMore: page + 1 < VideoMapper.number(data['pages']),
    );
  }
}

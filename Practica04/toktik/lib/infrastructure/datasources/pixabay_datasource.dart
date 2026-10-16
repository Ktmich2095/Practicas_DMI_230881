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
  bool get available =>
      api.usesGateway || (api.allowDirectKeys && key.trim().isNotEmpty);
  @override
  Future<VideoBatch> fetch(int page) async {
    if (!available) {
      throw const SourceException(
        'Pixabay sin configuración de acceso: clave de desarrollo o backend HTTPS.',
        code: 'configuration',
      );
    }
    final data = await api.getAuthenticated(
      'pixabay',
      Uri.https('pixabay.com', '/api/videos/', {
        'key': key.trim(),
        'page': '${page + 1}',
        'per_page': '${ApiConfig.pageSize}',
        'safesearch': 'true',
        'order': 'popular',
      }),
    );
    if (data['hits'] is! List) {
      throw const SourceException(
        'Pixabay: respuesta sin lista hits.',
        code: 'response_schema',
      );
    }
    final videos = VideoMapper.maps(data['hits'])
        .map(VideoMapper.pixabay)
        .whereType<VideoPost>()
        .toList();
    if ((data['hits'] as List).isNotEmpty && videos.isEmpty) {
      throw const SourceException(
        'Pixabay: no hay variante MP4 válida en el catálogo recibido.',
        code: 'mapping',
      );
    }
    return VideoBatch(
      source: source,
      videos: videos,
      hasMore:
          (page + 1) * ApiConfig.pageSize <
          VideoMapper.number(data['totalHits']),
    );
  }
}

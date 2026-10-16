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
  bool get available =>
      api.usesGateway || (api.allowDirectKeys && key.trim().isNotEmpty);
  @override
  Future<VideoBatch> fetch(int page) async {
    if (!available) {
      throw const SourceException(
        'Coverr sin configuración de acceso: clave de desarrollo o backend HTTPS.',
        code: 'configuration',
      );
    }
    final data = await api.getAuthenticated(
      'coverr',
      Uri.https('api.coverr.co', '/videos', {
        'page': '$page',
        'page_size': '${ApiConfig.pageSize}',
        'urls': 'true',
        'sort': 'popular',
      }),
      headers: {'Authorization': 'Bearer ${key.trim()}'},
    );
    if (data['hits'] is! List) {
      throw const SourceException(
        'Coverr: respuesta sin lista hits.',
        code: 'response_schema',
      );
    }
    final videos = VideoMapper.maps(data['hits'])
        .map(VideoMapper.coverr)
        .whereType<VideoPost>()
        .toList();
    if ((data['hits'] as List).isNotEmpty && videos.isEmpty) {
      throw const SourceException(
        'Coverr: no hay URL MP4 válida en el catálogo recibido.',
        code: 'mapping',
      );
    }
    return VideoBatch(
      source: source,
      videos: videos,
      hasMore: page + 1 < VideoMapper.number(data['pages']),
    );
  }
}

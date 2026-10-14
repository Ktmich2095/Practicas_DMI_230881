import '../../domain/datasources/video_source_datasource.dart';
import '../../domain/entities/video_batch.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/entities/video_post.dart';
import '../mappers/video_mapper.dart';
import 'json_api_client.dart';

class ArchiveDatasource implements VideoSourceDatasource {
  final JsonApiClient api;
  ArchiveDatasource(this.api);
  @override
  VideoSource get source => VideoSource.archive;
  @override
  bool get available => true;
  @override
  Future<VideoBatch> fetch(int page) async {
    const query =
        'mediatype:movies AND (licenseurl:"https://creativecommons.org/publicdomain/zero/1.0/" OR licenseurl:"http://creativecommons.org/publicdomain/zero/1.0/" OR licenseurl:"https://creativecommons.org/licenses/by/4.0/" OR licenseurl:"http://creativecommons.org/licenses/by/4.0/")';
    final data = await api.get(
      Uri.https('archive.org', '/advancedsearch.php', {
        'q': query,
        'output': 'json',
        'rows': '6',
        'page': '${page + 1}',
        'fl[]': 'identifier',
        'sort[]': 'downloads desc',
      }),
    );
    final response = VideoMapper.map(data['response']);
    final docs = VideoMapper.maps(response['docs']);
    final videos = <VideoPost>[];
    // Two concurrent metadata requests per batch; isolate a failed item.
    for (var i = 0; i < docs.length; i += 2) {
      final results = await Future.wait(
        docs.skip(i).take(2).map((doc) async {
          final id = VideoMapper.text(doc['identifier']);
          if (id.isEmpty) return <VideoPost>[];
          try {
            final metadata = await api.get(
              Uri.https('archive.org', '/metadata/$id'),
            );
            return VideoMapper.archive(id, metadata);
          } catch (_) {
            return <VideoPost>[];
          }
        }),
      );
      videos.addAll(results.expand((v) => v));
    }
    return VideoBatch(
      source: source,
      videos: videos,
      hasMore: (page + 1) * 6 < VideoMapper.number(response['numFound']),
    );
  }
}

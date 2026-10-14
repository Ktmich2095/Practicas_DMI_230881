import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:toktik_app/domain/datasources/video_source_datasource.dart';
import 'package:toktik_app/domain/entities/video_batch.dart';
import 'package:toktik_app/domain/entities/video_post.dart';
import 'package:toktik_app/domain/entities/video_source.dart';
import 'package:toktik_app/infrastructure/datasources/json_api_client.dart';
import 'package:toktik_app/infrastructure/datasources/coverr_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/pixabay_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/archive_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/local_assets_datasource.dart';
import 'package:toktik_app/infrastructure/mappers/video_mapper.dart';
import 'package:toktik_app/infrastructure/repositories/fallback_video_repository.dart';

// Synthetic fixtures only. Live API verification is recorded separately.
class StubSource implements VideoSourceDatasource {
  @override
  final VideoSource source;
  @override
  final bool available;
  final List<VideoPost> videos;
  final bool fail;
  int calls = 0;
  StubSource(
    this.source,
    this.videos, {
    this.available = true,
    this.fail = false,
  });
  @override
  Future<VideoBatch> fetch(int page) async {
    calls++;
    if (fail) throw const SourceException('HTTP 503');
    return VideoBatch(videos: videos, source: source);
  }
}

const localVideo = VideoPost(
  caption: 'Original',
  videoUrl: 'assets/videos/aurora.mp4',
  providerId: 'local:aurora',
);

class HangingSource extends StubSource {
  HangingSource() : super(VideoSource.archive, []);
  @override
  Future<VideoBatch> fetch(int page) => Completer<VideoBatch>().future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'An unresponsive source reaches local fallback within its deadline',
    () async {
      final batch = await FallbackVideoRepository(
        [
          HangingSource(),
          StubSource(VideoSource.local, [localVideo]),
        ],
        sourceTimeout: const Duration(milliseconds: 20),
      ).fetch(VideoSource.archive);
      expect(batch.source, VideoSource.local);
      expect(batch.videos.single.id, localVideo.id);
      expect(batch.notices, isNotEmpty);
    },
  );
  test('Local fallback discovers the three real bundled MP4 assets', () async {
    final batch = await LocalAssetsDatasource().fetch(0);
    expect(batch.videos.length, 3);
    expect(
      batch.videos.every((v) => v.width == 360 && v.height == 640),
      isTrue,
    );
    expect((await LocalAssetsDatasource().fetch(1)).videos, isEmpty);
  });
  test('Coverr uses verified endpoint, bearer and preview URLs', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.coverr.co');
      expect(request.url.path, '/videos');
      expect(request.url.queryParameters['urls'], 'true');
      expect(request.url.queryParameters['page'], '2');
      expect(request.headers['Authorization'], 'Bearer test-placeholder');
      return http.Response(
        jsonEncode({
          'pages': 4,
          'hits': [
            {
              'id': 'fixture',
              'title': 'Fixture',
              'urls': {
                'mp4_preview': 'https://storage.coverr.co/videos/fixture/preview?token=fake',
              },
            },
            {'id': 'invalid'},
            null,
          ],
        }),
        200,
      );
    });
    final result = await CoverrDatasource(
      JsonApiClient(client),
      key: 'test-placeholder',
    ).fetch(2);
    expect(result.videos.single.id, 'coverr:fixture');
    expect(result.hasMore, isTrue);
    client.close();
  });
  test('Pixabay maps small rendition, metadata and one-based pages', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/videos/');
      expect(request.url.queryParameters['page'], '1');
      expect(request.url.queryParameters['key'], 'test-placeholder');
      return http.Response(
        jsonEncode({
          'totalHits': 1,
          'hits': [
            {
              'id': 7,
              'user': 'Fixture author',
              'tags': 'nature',
              'likes': 12,
              'videos': {
                'large': {'url': '', 'size': 0},
                'small': {
                  'url': 'https://cdn.pixabay.com/video/fixture.mp4',
                  'size': 1000,
                  'width': 360,
                  'height': 640,
                },
              },
            },
          ],
        }),
        200,
      );
    });
    final result = await PixabayDatasource(
      JsonApiClient(client),
      key: 'test-placeholder',
    ).fetch(0);
    expect(result.videos.single.id, 'pixabay:7');
    expect(result.videos.single.height, 640);
    expect(result.videos.single.likes, 12);
    client.close();
  });
  test('Missing keys do not issue HTTP requests', () async {
    final client = MockClient(
      (_) async => throw StateError('must not request'),
    );
    expect(CoverrDatasource(JsonApiClient(client), key: '').available, isFalse);
    await expectLater(
      PixabayDatasource(JsonApiClient(client), key: '').fetch(0),
      throwsA(isA<SourceException>()),
    );
    client.close();
  });
  test(
    'Archive searches real endpoint and isolates inaccessible metadata',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/advancedsearch.php') {
          expect(request.url.queryParameters['output'], 'json');
          return http.Response(
            jsonEncode({
              'response': {
                'numFound': 2,
                'docs': [
                  {'identifier': 'fixture-item'},
                  {'identifier': 'unavailable'},
                ],
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('unavailable')) {
          return http.Response('not available', 503);
        }
        expect(request.url.path, '/metadata/fixture-item');
        return http.Response(
          jsonEncode({
            'metadata': {
              'title': 'Fixture',
              'licenseurl':
                  'https://creativecommons.org/publicdomain/zero/1.0/',
              'description': '<p>A clip</p>',
            },
            'files': [
              {'name': 'bad.webm', 'size': '10'},
              {'name': 'clip one.mp4', 'size': '12000', 'format': 'h.264'},
              {'name': 'private.mp4', 'size': '1000', 'private': 'true'},
            ],
          }),
          200,
        );
      });
      final result = await ArchiveDatasource(JsonApiClient(client)).fetch(0);
      expect(
        result.videos.single.videoUrl,
        'https://archive.org/download/fixture-item/clip%20one.mp4',
      );
      expect(result.videos.single.caption, 'A clip');
      client.close();
    },
  );
  test(
    'Archive rejects missing licenses, private items and incompatible files',
    () {
      expect(VideoMapper.archive('x', {'metadata': {}, 'files': []}), isEmpty);
      expect(VideoMapper.archive('x', {'is_dark': true}), isEmpty);
      expect(VideoMapper.pixabay({'id': 1, 'videos': {}}), isNull);
    },
  );
  test('HTTP and malformed JSON become sanitized source errors', () async {
    for (final response in [
      http.Response('secret diagnostic', 403),
      http.Response('invalid', 200),
      http.Response('[]', 200),
    ]) {
      final client = MockClient((_) async => response);
      await expectLater(
        JsonApiClient(client).get(Uri.https('example.org', '/fixture')),
        throwsA(isA<SourceException>()),
      );
      client.close();
    }
  });
  test('Preferred failure falls back, validates and deduplicates', () async {
    final preferred = StubSource(VideoSource.coverr, [], fail: true);
    final fallback = StubSource(VideoSource.local, [
      localVideo,
      localVideo,
      const VideoPost(
        caption: 'bad',
        videoUrl: 'https://example.org/not-video.html',
        origin: VideoSource.archive,
      ),
    ]);
    final result = await FallbackVideoRepository([fallback, preferred])
        .fetch(VideoSource.coverr);
    expect(preferred.calls, 1);
    expect(result.source, VideoSource.local);
    expect(result.videos.length, 1);
    expect(result.notices.single, contains('503'));
  });
  test(
    'All sources empty or disabled report no reproducible content',
    () async {
      final unavailable = StubSource(VideoSource.coverr, [], available: false);
      final result = await FallbackVideoRepository([
        unavailable,
        StubSource(VideoSource.local, []),
      ], random: Random(3)).fetch(VideoSource.random);
      expect(unavailable.calls, 0);
      expect(result.videos, isEmpty);
      expect(result.notices.length, 2);
    },
  );
}

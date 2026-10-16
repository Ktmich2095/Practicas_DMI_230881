import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:toktik_app/domain/datasources/video_source_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/json_api_client.dart';
import 'package:toktik_app/infrastructure/datasources/coverr_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/pixabay_datasource.dart';
import 'package:toktik_app/infrastructure/mappers/video_mapper.dart';
import 'package:toktik_app/presentation/providers/playback_coordinator.dart';

void main() {
  for (final status in [401, 403, 404, 429, 500]) {
    test(
      'HTTP $status retains safe status without response body or signed URL',
      () async {
        final client = MockClient(
          (_) async =>
              http.Response('private-key signed-url?token=secret', status),
        );
        final api = JsonApiClient(client);
        try {
          await api.get(
            Uri.https('example.org', '/catalog', {'key': 'private-key'}),
          );
          fail('Expected an HTTP failure');
        } on SourceException catch (error) {
          expect(error.httpStatus, status);
          expect(error.code, 'http');
          expect(error.message, contains('$status'));
          expect(error.message, isNot(contains('private-key')));
          expect(error.toString(), isNot(contains('token=')));
        } finally {
          client.close();
        }
      },
    );
  }
  test(
    'Gateway receives only pagination, with no upstream credentials',
    () async {
      final seen = <http.Request>[];
      final client = MockClient((request) async {
        seen.add(request);
        expect(request.url.host, 'catalog.example.org');
        expect(request.url.path, startsWith('/api/v1/videos/'));
        expect(request.url.toString(), isNot(contains('fixture-private-key')));
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({'hits': [], 'pages': 0, 'totalHits': 0}),
          200,
        );
      });
      final api = JsonApiClient(
        client,
        gatewayBaseUrl: 'https://catalog.example.org/api/',
        allowDirectKeys: false,
      );
      await CoverrDatasource(api, key: 'fixture-private-key').fetch(0);
      await PixabayDatasource(api, key: 'fixture-private-key').fetch(0);
      expect(seen.length, 2);
      expect(seen[0].url.queryParameters['page'], '0');
      expect(seen[1].url.queryParameters['page'], '1');
      client.close();
    },
  );
  test('Release without backend does not send direct credentials', () async {
    final client = MockClient(
      (_) async => throw StateError('No network request allowed'),
    );
    final api = JsonApiClient(
      client,
      allowDirectKeys: false,
      gatewayBaseUrl: '',
    );
    expect(
      CoverrDatasource(api, key: 'fixture-private-key').available,
      isFalse,
    );
    expect(
      PixabayDatasource(api, key: 'fixture-private-key').available,
      isFalse,
    );
    expect(
      () =>
          api.getAuthenticated('coverr', Uri.https('api.coverr.co', '/videos')),
      throwsA(
        isA<SourceException>().having((e) => e.code, 'code', 'configuration'),
      ),
    );
    client.close();
  });
  test(
    'Gateway rejects cleartext, embedded credentials and query configuration',
    () async {
      final client = MockClient(
        (_) async => throw StateError('No network request allowed'),
      );
      for (final url in [
        'http://catalog.example.org',
        'https://user:secret@catalog.example.org',
        'https://catalog.example.org?key=secret',
      ]) {
        final api = JsonApiClient(client, gatewayBaseUrl: url);
        expect(
          () => api.getAuthenticated(
            'coverr',
            Uri.https('api.coverr.co', '/videos'),
          ),
          throwsA(isA<SourceException>()),
        );
      }
      client.close();
    },
  );
  test(
    'Valid HTTP with unusable catalog distinguishes schema and mapping',
    () async {
      for (final body in [
        {'videos': []},
        {
          'hits': [
            {'id': 'unusable'},
          ],
        },
      ]) {
        final client = MockClient(
          (_) async => http.Response(jsonEncode(body), 200),
        );
        await expectLater(
          CoverrDatasource(JsonApiClient(client), key: 'fixture').fetch(0),
          throwsA(
            isA<SourceException>().having(
              (e) => e.code,
              'stage',
              anyOf('response_schema', 'mapping'),
            ),
          ),
        );
        client.close();
      }
    },
  );
  test('Pixabay prefers smaller valid rendition over larger media', () {
    final video = VideoMapper.pixabay({
      'id': 1,
      'videos': {
        'tiny': {'url': 'https://cdn.pixabay.com/video/tiny.mp4', 'size': 100},
        'small': {
          'url': 'https://cdn.pixabay.com/video/small.mp4',
          'size': 1000,
        },
      },
    });
    expect(video!.videoUrl, endsWith('/tiny.mp4'));
  });
  test('Playback diagnostics redact native messages, tokens and URLs', () {
    expect(
      PlaybackCoordinator.safePlaybackError(
        'Source error HTTP response code: 403 https://cdn.example/a.mp4?token=private',
      ),
      contains('HTTP 403'),
    );
    for (final raw in [
      'decoder failed secret-token',
      'https://private.example/key?token=secret',
      'status code: 429 private-key',
    ]) {
      final safe = PlaybackCoordinator.safePlaybackError(raw);
      expect(safe, isNot(contains('secret')));
      expect(safe, isNot(contains('https://')));
      expect(safe, isNot(contains('private-key')));
    }
  });
}

// Separate release-only test entry point. Never upload this APK to Appetize.
// It trusts only the exact temporary localhost certificate passed by the test.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:video_player/video_player.dart';
import 'package:toktik_app/config/api/api_config.dart';
import 'package:toktik_app/domain/datasources/video_source_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/coverr_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/pixabay_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/archive_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/local_assets_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/json_api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _Probe()));
}

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  VideoPlayerController? controller;
  String status = 'Release verification';
  @override
  void initState() {
    super.initState();
    unawaited(run());
  }

  void report(Map<String, Object?> data) {
    // Only bounded codes, source names, counts and booleans. No URLs or errors.
    // ignore: avoid_print
    print('TOKTIK_RELEASE_PROBE ${jsonEncode(data)}');
  }

  Future<void> run() async {
    const expected = String.fromEnvironment('TEST_GATEWAY_CERT_DER');
    final io = HttpClient()
      ..badCertificateCallback = (cert, host, port) =>
          host == 'localhost' &&
          port == 8765 &&
          expected.isNotEmpty &&
          base64Url.encode(cert.der) == expected;
    final client = IOClient(io);
    final api = JsonApiClient(client);
    report({
      'stage': 'config',
      'releaseKeysEmpty':
          ApiConfig.coverrKey.isEmpty && ApiConfig.pixabayKey.isEmpty,
    });
    final sources = <VideoSourceDatasource>[
      CoverrDatasource(api),
      PixabayDatasource(api),
      ArchiveDatasource(api),
      LocalAssetsDatasource(),
    ];
    for (final source in sources) {
      try {
        if (mounted) setState(() => status = source.source.name);
        final batch = await source
            .fetch(0)
            .timeout(const Duration(seconds: 35));
        if (batch.videos.isEmpty) {
          report({
            'source': source.source.name,
            'stage': 'catalog',
            'ok': false,
            'code': 'empty',
          });
          continue;
        }
        report({
          'source': source.source.name,
          'stage': 'catalog',
          'ok': true,
          'count': batch.videos.length,
        });
        final video = batch.videos.first;
        final c =
            video.origin == source.source &&
                video.videoUrl.startsWith('https://')
            ? VideoPlayerController.networkUrl(Uri.parse(video.videoUrl))
            : VideoPlayerController.asset(video.videoUrl);
        controller = c;
        if (mounted) setState(() {});
        try {
          await c.initialize().timeout(const Duration(seconds: 45));
          if (mounted) setState(() {});
          await c.setVolume(0);
          await c.play();
          for (
            var i = 0;
            i < 40 &&
                c.value.position < const Duration(milliseconds: 500) &&
                !c.value.hasError;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          report({
            'source': source.source.name,
            'stage': 'playback',
            'initialized': c.value.isInitialized,
            'progress': c.value.position >= const Duration(milliseconds: 500),
            'ok':
                !c.value.hasError &&
                c.value.position >= const Duration(milliseconds: 500),
          });
        } finally {
          await c.dispose();
          controller = null;
        }
      } on SourceException catch (error) {
        report({
          'source': source.source.name,
          'stage': 'catalog',
          'ok': false,
          'code': error.code,
          'httpStatus': error.httpStatus,
        });
      } catch (_) {
        report({
          'source': source.source.name,
          'stage': 'playback_or_network',
          'ok': false,
          'code': 'verification_failed',
        });
      }
    }
    client.close();
    report({'stage': 'complete'});
    if (mounted) setState(() => status = 'Verification complete');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status),
          if (controller?.value.isInitialized == true)
            SizedBox(height: 240, width: 180, child: VideoPlayer(controller!)),
        ],
      ),
    ),
  );
}

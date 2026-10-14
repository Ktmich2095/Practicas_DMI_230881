import 'dart:math';

import '../../domain/repositories/video_catalog_repository.dart';
import '../../domain/datasources/video_source_datasource.dart';
import '../../domain/entities/video_batch.dart';
import '../../domain/entities/video_source.dart';
import '../datasources/local_assets_datasource.dart';

class FallbackVideoRepository implements VideoCatalogRepository {
  final List<VideoSourceDatasource> datasources;
  final Random random;
  final Duration sourceTimeout;
  FallbackVideoRepository(
    this.datasources, {
    Random? random,
    this.sourceTimeout = const Duration(seconds: 20),
  }) : random = random ?? Random();
  @override
  Future<VideoBatch> fetch(VideoSource selected, {int page = 0}) async {
    final order = List<VideoSourceDatasource>.of(datasources);
    if (selected == VideoSource.random) {
      order.shuffle(random);
    } else {
      order.sort(
        (a, b) => a.source == selected
            ? -1
            : b.source == selected
            ? 1
            : a.source.index.compareTo(b.source.index),
      );
    }
    final notices = <String>[];
    for (final datasource in order) {
      if (!datasource.available) {
        notices.add('${datasource.source.label}: credencial no configurada');
        continue;
      }
      try {
        final batch = await datasource
            .fetch(
              datasource.source == selected || selected == VideoSource.random
                  ? page
                  : 0,
            )
            .timeout(sourceTimeout);
        final seen = <String>{};
        final videos = batch.videos
            .where((v) => LocalAssetsDatasource.valid(v) && seen.add(v.id))
            .toList();
        if (videos.isNotEmpty) {
          return VideoBatch(
            videos: videos,
            source: datasource.source,
            hasMore: batch.hasMore,
            notices: [...notices, ...batch.notices],
          );
        }
        notices.add('${datasource.source.label}: sin videos compatibles');
      } catch (error) {
        notices.add(
          '${datasource.source.label}: ${error is SourceException ? error.message : 'fuente no disponible'}',
        );
      }
    }
    return VideoBatch(videos: const [], source: selected, notices: notices);
  }
}

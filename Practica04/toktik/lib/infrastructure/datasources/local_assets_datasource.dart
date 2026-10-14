import 'package:flutter/services.dart';

import '../../domain/datasources/video_source_datasource.dart';
import '../../domain/entities/video_batch.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/entities/video_post.dart';

class LocalAssetsDatasource implements VideoSourceDatasource {
  final AssetBundle bundle;
  LocalAssetsDatasource({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;
  @override
  VideoSource get source => VideoSource.local;
  @override
  bool get available => true;
  @override
  Future<VideoBatch> fetch(int page) async {
    if (page > 0) return VideoBatch(videos: const [], source: source);
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final paths =
        manifest
            .listAssets()
            .where(
              (p) =>
                  p.startsWith('assets/videos/') &&
                  p.toLowerCase().endsWith('.mp4'),
            )
            .toList()
          ..sort();
    return VideoBatch(source: source, videos: paths.map(_post).toList());
  }

  static VideoPost _post(String path) {
    final name = path.split('/').last.split('.').first;
    final original = const {'aurora', 'atardecer', 'orbita'}.contains(name);
    return VideoPost(
      providerId: 'local:$path',
      caption: original
          ? 'TokTik · $name. Animación original generada para esta práctica.'
          : name.replaceAll('_', ' '),
      creator: original ? 'TokTik Studio' : 'Video local',
      source: 'Videos locales',
      origin: VideoSource.local,
      videoUrl: path,
      license: original ? 'Recurso original de la práctica' : null,
      width: original ? 360 : null,
      height: original ? 640 : null,
    );
  }

  static bool isAsset(String url) =>
      url.startsWith('assets/videos/') && url.endsWith('.mp4');
  static bool validRemote(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return false;
    }
    // Coverr's documented MP4 links do not have a file extension.
    return uri.path.toLowerCase().endsWith('.mp4') ||
        ((uri.host == 'storage.coverr.co' || uri.host.endsWith('.coverr.co')) &&
            uri.path.startsWith('/videos/'));
  }

  static bool valid(VideoPost video) =>
      video.id.isNotEmpty &&
      (video.origin == VideoSource.local
          ? isAsset(video.videoUrl)
          : validRemote(video.videoUrl));
}

import '../../domain/entities/video_post.dart';
import '../../domain/entities/video_source.dart';

/// Defensive mappers: a malformed hit cannot discard the entire page.
class VideoMapper {
  static Map<String, dynamic> map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};
  static String text(Object? v) =>
      v is List ? v.map(text).join(', ') : v?.toString() ?? '';
  static int number(Object? v) => int.tryParse(text(v)) ?? 0;
  static List<Map<String, dynamic>> maps(Object? v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  static String plain(Object? v) =>
      text(v).replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
  static VideoPost? coverr(Map<String, dynamic> hit) {
    final id = text(hit['id']);
    final urls = map(hit['urls']);
    final url = text(urls['mp4_preview']).isNotEmpty
        ? text(urls['mp4_preview'])
        : text(urls['mp4']);
    if (id.isEmpty || url.isEmpty) return null;
    return VideoPost(
      providerId: 'coverr:$id',
      videoUrl: url,
      caption: plain(hit['description']).isNotEmpty
          ? plain(hit['description'])
          : text(hit['title']),
      creator: text(hit['creator']).isEmpty ? 'Coverr' : text(hit['creator']),
      source: 'Coverr',
      origin: VideoSource.coverr,
      sourcePage: 'https://coverr.co',
      views: number(hit['views']),
      likes: number(hit['likes']),
      width: number(hit['max_width']),
      height: number(hit['max_height']),
    );
  }

  static VideoPost? pixabay(Map<String, dynamic> hit) {
    final id = text(hit['id']);
    final renditions = map(hit['videos']);
    Map<String, dynamic> rendition = {};
    for (final size in ['small', 'medium', 'tiny', 'large']) {
      final candidate = map(renditions[size]);
      if (text(candidate['url']).isNotEmpty && number(candidate['size']) > 0) {
        rendition = candidate;
        break;
      }
    }
    if (id.isEmpty || rendition.isEmpty) return null;
    return VideoPost(
      providerId: 'pixabay:$id',
      videoUrl: text(rendition['url']),
      caption: text(hit['tags']),
      creator: text(hit['user']),
      source: 'Pixabay',
      origin: VideoSource.pixabay,
      sourcePage: text(hit['pageURL']),
      license: 'Pixabay Content License',
      views: number(hit['views']),
      likes: number(hit['likes']),
      width: number(rendition['width']),
      height: number(rendition['height']),
    );
  }

  static List<VideoPost> archive(String identifier, Map<String, dynamic> data) {
    if (data['is_dark'] == true || data['is_dark'] == 'true') return [];
    final metadata = map(data['metadata']);
    final license = text(metadata['licenseurl']);
    // Restrict the public search to material explicitly declaring CC0 / PDM / CC BY.
    if (!isOpenLicense(license)) return [];
    final files =
        maps(data['files'])
            .where(
              (f) =>
                  text(f['name']).toLowerCase().endsWith('.mp4') &&
                  f['private'] != 'true' &&
                  f['private'] != true &&
                  number(f['size']) > 0 &&
                  number(f['size']) <= 80000000 &&
                  !text(f['format']).toLowerCase().contains('h.265'),
            )
            .toList()
          ..sort((a, b) => number(a['size']).compareTo(number(b['size'])));
    // One rendition per archive item; avoid duplicates and huge original films.
    if (files.isEmpty) return [];
    final file = files.first;
    final name = text(file['name']);
    return [
      VideoPost(
        providerId: 'archive:$identifier',
        videoUrl: Uri.https(
          'archive.org',
          '/download/$identifier/$name',
        ).toString(),
        caption: plain(metadata['description']).isEmpty
            ? text(metadata['title'])
            : plain(metadata['description']),
        creator: text(metadata['creator']).isEmpty
            ? 'Internet Archive'
            : text(metadata['creator']),
        source: 'Internet Archive',
        origin: VideoSource.archive,
        license: license,
        sourcePage: Uri.https('archive.org', '/details/$identifier').toString(),
        width: number(file['width']),
        height: number(file['height']),
      ),
    ];
  }

  static bool isOpenLicense(String license) {
    final uri = Uri.tryParse(license);
    return uri?.host == 'creativecommons.org' &&
        (uri!.path.startsWith('/publicdomain/zero/') ||
            uri.path.startsWith('/publicdomain/mark/') ||
            uri.path.startsWith('/licenses/by/'));
  }

  static Map<String, dynamic> toJson(VideoPost v) => {
    'id': v.id,
    'caption': v.caption,
    'url': v.videoUrl,
    'creator': v.creator,
    'source': v.source,
    'origin': v.origin.name,
    'sourcePage': v.sourcePage,
    'license': v.license,
    'likes': v.likes,
    'views': v.views,
    'width': v.width,
    'height': v.height,
  };
  static VideoPost fromJson(Map<String, dynamic> json) => VideoPost(
    providerId: text(json['id']),
    videoUrl: text(json['url']),
    caption: text(json['caption']),
    creator: text(json['creator']),
    source: text(json['source']),
    origin: VideoSource.parse(json['origin']),
    sourcePage: json['sourcePage'] as String?,
    license: json['license'] as String?,
    likes: number(json['likes']),
    views: number(json['views']),
    width: json['width'] as int?,
    height: json['height'] as int?,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:toktik_app/config/api/api_config.dart';
import 'package:toktik_app/infrastructure/datasources/json_api_client.dart';
import 'package:toktik_app/infrastructure/datasources/coverr_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/pixabay_datasource.dart';
import 'package:toktik_app/infrastructure/datasources/local_assets_datasource.dart';

// Opt-in only: network availability and account quotas are external to CI.
const live = bool.fromEnvironment('RUN_LIVE_APIS');
void main() {
  for (final provider in ['Coverr', 'Pixabay']) {
    test(
      '$provider authenticated live response maps to valid VideoPost entities',
      () async {
        final client = http.Client();
        try {
          final api = JsonApiClient(client);
          final datasource = provider == 'Coverr'
              ? CoverrDatasource(api)
              : PixabayDatasource(api);
          expect(
            provider == 'Coverr'
                ? ApiConfig.coverrKey.isNotEmpty
                : ApiConfig.pixabayKey.isNotEmpty,
            isTrue,
            reason: 'A compile-time API key is required',
          );
          final batch = await datasource.fetch(0);
          expect(
            batch.videos,
            isNotEmpty,
            reason: 'The real API must return usable videos',
          );
          expect(batch.videos.every(LocalAssetsDatasource.valid), isTrue);
          // Only counts are logged: no keys, signed media URLs or response bodies.
          // ignore: avoid_print
          print('$provider: ${batch.videos.length} mapped videos');
        } finally {
          client.close();
        }
      },
      skip: !live
          ? 'Enable RUN_LIVE_APIS with runtime credentials to contact the real API'
          : false,
      timeout: const Timeout(Duration(seconds: 45)),
    );
  }
}

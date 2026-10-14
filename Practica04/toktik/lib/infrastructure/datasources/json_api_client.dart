import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api/api_config.dart';
import '../../domain/datasources/video_source_datasource.dart';

class JsonApiClient {
  final http.Client client;
  JsonApiClient(this.client);
  Future<Map<String, dynamic>> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode != 200) {
        throw SourceException('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const SourceException('Respuesta JSON incompatible');
      }
      return data;
    } on SourceException {
      rethrow;
    } catch (_) {
      throw const SourceException('Error de red o JSON inválido');
    }
  }
}

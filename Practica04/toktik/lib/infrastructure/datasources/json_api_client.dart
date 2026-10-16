import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../config/api/api_config.dart';
import '../../domain/datasources/video_source_datasource.dart';

class JsonApiClient {
  final http.Client client;
  final String gatewayBaseUrl;
  final bool allowDirectKeys;
  JsonApiClient(
    this.client, {
    this.gatewayBaseUrl = ApiConfig.gatewayBaseUrl,
    this.allowDirectKeys = !kReleaseMode,
  });
  bool get usesGateway => gatewayBaseUrl.trim().isNotEmpty;

  Future<Map<String, dynamic>> getAuthenticated(
    String provider,
    Uri upstream, {
    Map<String, String>? headers,
  }) {
    if (usesGateway) {
      final base = Uri.tryParse(gatewayBaseUrl.trim());
      if (base == null ||
          base.scheme != 'https' ||
          base.host.isEmpty ||
          base.userInfo.isNotEmpty ||
          base.hasQuery ||
          base.hasFragment) {
        throw const SourceException(
          'Backend inválido: se requiere una URL HTTPS sin credenciales.',
          code: 'configuration',
        );
      }
      if (!const ['coverr', 'pixabay'].contains(provider)) {
        throw const SourceException(
          'Proveedor no permitido.',
          code: 'configuration',
        );
      }
      // Only public pagination values leave the device. Never forward auth.
      final query = <String, String>{};
      for (final name in ['page', 'page_size', 'per_page']) {
        final value = upstream.queryParameters[name];
        if (value != null) query[name] = value;
      }
      final path =
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}/v1/videos/$provider';
      return get(base.replace(path: path, queryParameters: query));
    }
    if (!allowDirectKeys) {
      throw const SourceException(
        'Falta TOKTIK_API_BASE_URL: release requiere un backend HTTPS.',
        code: 'configuration',
      );
    }
    return get(upstream, headers: headers);
  }

  Future<Map<String, dynamic>> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode != 200) {
        final status = response.statusCode;
        final detail = switch (status) {
          401 => 'autenticación rechazada',
          403 =>
            'acceso denegado; revisar cuenta, permisos o protección de acceso',
          404 => 'endpoint no encontrado',
          429 => 'límite de solicitudes; reintenta más tarde',
          >= 500 => 'servicio remoto no disponible',
          _ => 'consulta de catálogo rechazada',
        };
        throw SourceException(
          'HTTP $status: $detail.',
          code: 'http',
          httpStatus: status,
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const SourceException(
          'Respuesta JSON incompatible.',
          code: 'response_schema',
        );
      }
      return data;
    } on SourceException {
      rethrow;
    } on TimeoutException {
      throw const SourceException(
        'Tiempo de espera agotado al consultar el catálogo.',
        code: 'timeout',
      );
    } on FormatException {
      throw const SourceException(
        'El catálogo no devolvió JSON válido.',
        code: 'response_schema',
      );
    } catch (_) {
      throw const SourceException(
        'No se pudo conectar al catálogo (red o TLS).',
        code: 'network',
      );
    }
  }
}

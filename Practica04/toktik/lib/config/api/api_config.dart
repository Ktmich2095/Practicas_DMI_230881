import 'package:flutter/foundation.dart';

/// Release contains only a public backend URL. Direct keys are development-only.
class ApiConfig {
  static const gatewayBaseUrl = String.fromEnvironment('TOKTIK_API_BASE_URL');
  static const coverrKey = kReleaseMode
      ? ''
      : String.fromEnvironment('COVERR_API_KEY');
  static const pixabayKey = kReleaseMode
      ? ''
      : String.fromEnvironment('PIXABAY_API_KEY');
  static const requestTimeout = Duration(seconds: 12);
  static const pageSize = 8;
}

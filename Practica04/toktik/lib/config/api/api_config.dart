/// Compile-time values; never put real keys in source control.
class ApiConfig {
  static const coverrKey = String.fromEnvironment('COVERR_API_KEY');
  static const pixabayKey = String.fromEnvironment('PIXABAY_API_KEY');
  static const requestTimeout = Duration(seconds: 12);
  static const pageSize = 8;
}

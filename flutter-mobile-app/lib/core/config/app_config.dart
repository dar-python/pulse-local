import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _defaultApiBaseUrl = 'http://10.0.2.2:8000/api/';

  static String get apiBaseUrl {
    const dartDefineValue = String.fromEnvironment('API_BASE_URL');

    if (dartDefineValue.trim().isNotEmpty) {
      return _normalizeBaseUrl(dartDefineValue);
    }

    String? dotenvValue;

    try {
      dotenvValue = dotenv.env['API_BASE_URL'];
    } catch (_) {
      dotenvValue = null;
    }

    if (dotenvValue != null && dotenvValue.trim().isNotEmpty) {
      return _normalizeBaseUrl(dotenvValue);
    }

    return _defaultApiBaseUrl;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.endsWith('/')) {
      return trimmed;
    }

    return '$trimmed/';
  }
}
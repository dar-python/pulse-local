import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _productionBaseUrl =
      'https://foodpulse-zuniega-docil.duckdns.org';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8080';
  static const String _windowsDesktopBaseUrl = 'http://127.0.0.1:8080';

  static String get apiBaseUrl {
    const laravelDartDefineValue = String.fromEnvironment('LARAVEL_BASE_URL');
    const legacyDartDefineValue = String.fromEnvironment('API_BASE_URL');

    if (laravelDartDefineValue.trim().isNotEmpty) {
      return _normalizeLaravelBaseUrl(laravelDartDefineValue);
    }

    if (legacyDartDefineValue.trim().isNotEmpty) {
      return _normalizeLaravelBaseUrl(legacyDartDefineValue);
    }

    String? dotenvValue;

    try {
      dotenvValue =
          dotenv.env['LARAVEL_BASE_URL'] ?? dotenv.env['API_BASE_URL'];
    } catch (_) {
      dotenvValue = null;
    }

    if (dotenvValue != null && dotenvValue.trim().isNotEmpty) {
      return _normalizeLaravelBaseUrl(dotenvValue);
    }

    return _defaultLaravelBaseUrl;
  }

  static String get laravelBaseUrl => apiBaseUrl;

  static String get _defaultLaravelBaseUrl {
    if (!kDebugMode) {
      return _productionBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorBaseUrl;
    }

    return _windowsDesktopBaseUrl;
  }

  static String _normalizeLaravelBaseUrl(String value) {
    var trimmed = value.trim();

    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }

    if (kDebugMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null &&
          (uri.host == '127.0.0.1' || uri.host.toLowerCase() == 'localhost')) {
        return uri
            .replace(host: Uri.parse(_androidEmulatorBaseUrl).host)
            .toString();
      }
    }

    return trimmed;
  }
}

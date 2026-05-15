import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL'];

    if (value == null || value.trim().isEmpty) {
      throw StateError('Missing API_BASE_URL in Flutter .env file.');
    }

    return value;
  }
}

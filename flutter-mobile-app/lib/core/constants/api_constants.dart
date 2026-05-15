import '../config/app_config.dart';

class ApiConstants {
  const ApiConstants._();

  static String get laravelBaseUrl => AppConfig.apiBaseUrl;

  static const String checkoutRiskEndpoint = 'checkout/risk';
}

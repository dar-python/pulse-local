import '../config/app_config.dart';

class ApiConstants {
  const ApiConstants._();

  static String get laravelBaseUrl => AppConfig.laravelBaseUrl;

  static const String checkoutRiskEndpoint = '/api/checkout/risk';
}

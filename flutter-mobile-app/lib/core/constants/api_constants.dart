import '../config/app_config.dart';

class ApiConstants {
  const ApiConstants._();

  static String get laravelBaseUrl => AppConfig.laravelBaseUrl;

  static const String authRegisterEndpoint = '/api/auth/register';
  static const String authLoginEndpoint = '/api/auth/login';
  static const String authProfileEndpoint = '/api/auth/profile';
  static const String authPasswordEndpoint = '/api/auth/password';
  static const String checkoutRiskEndpoint = '/api/checkout/risk';
}

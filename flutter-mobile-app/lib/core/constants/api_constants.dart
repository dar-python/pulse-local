class ApiConstants {
  const ApiConstants._();

  // Android emulator usually reaches the host machine at http://10.0.2.2:8000.
  // iOS simulator and desktop development may use http://localhost:8000.
  // Override with: --dart-define=LARAVEL_API_BASE_URL=http://your-host:8000
  static const String laravelBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String checkoutRiskEndpoint = '/api/checkout/risk';
}

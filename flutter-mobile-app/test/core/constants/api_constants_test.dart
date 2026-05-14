import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/constants/api_constants.dart';

void main() {
  test('Flutter targets the Laravel checkout risk endpoint only', () {
    expect(ApiConstants.checkoutRiskEndpoint, '/api/checkout/risk');
    expect(ApiConstants.laravelBaseUrl, isNot(contains('ml-service')));
    expect(ApiConstants.laravelBaseUrl, isNot(contains('5000')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulse_local_app/core/constants/api_constants.dart';

void main() {
  test('Flutter targets the Laravel checkout risk endpoint only', () {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://10.0.2.2:8000/api');

    expect(ApiConstants.checkoutRiskEndpoint, 'checkout/risk');
    expect(ApiConstants.laravelBaseUrl, isNot(contains('ml-service')));
    expect(ApiConstants.laravelBaseUrl, isNot(contains('5000')));
  });
}

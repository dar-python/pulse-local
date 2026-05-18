import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulse_local_app/core/constants/api_constants.dart';

void main() {
  test('Flutter targets the Laravel checkout risk endpoint only', () {
    dotenv.testLoad(fileInput: 'LARAVEL_BASE_URL=http://10.0.2.2:8000');

    expect(ApiConstants.checkoutRiskEndpoint, '/api/checkout/risk');
    expect(ApiConstants.laravelBaseUrl, isNot(contains('ml-service')));
    expect(ApiConstants.laravelBaseUrl, isNot(contains('5000')));
  });

  test('Flutter lib code does not call FastAPI or the ML service directly', () {
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in libFiles) {
      final source = file.readAsStringSync();

      expect(source, isNot(contains(':8001')), reason: file.path);
      expect(source, isNot(contains('/predict')), reason: file.path);
      expect(source, isNot(contains('ml-service')), reason: file.path);
    }
  });
}

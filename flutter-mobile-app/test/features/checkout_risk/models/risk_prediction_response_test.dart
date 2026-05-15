import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';

void main() {
  test('parses the Laravel wrapped ml-service risk prediction response', () {
    final response = RiskPredictionResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {
        'risk_score': 0.71,
        'risk_level': 'High',
        'recommendation':
            'High fulfillment risk. Adjust ETA and notify merchant.',
      },
    });

    expect(response.success, isTrue);
    expect(response.source, 'ml-service');
    expect(response.riskScore, 0.71);
    expect(response.riskLevel, 'High');
    expect(
      response.recommendation,
      'High fulfillment risk. Adjust ETA and notify merchant.',
    );
  });

  test('uses fallback values when optional response fields are missing', () {
    final response = RiskPredictionResponse.fromJson({
      'success': true,
      'data': {'risk_score': 0.25},
    });

    expect(response.source, 'unknown');
    expect(response.riskLevel, 'Unknown');
    expect(response.recommendation, 'No recommendation was returned.');
  });
}

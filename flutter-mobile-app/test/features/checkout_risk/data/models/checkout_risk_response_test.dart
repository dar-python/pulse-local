import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/data/models/checkout_risk_response.dart';

void main() {
  test('parses a Laravel ml-service checkout risk response', () {
    final response = CheckoutRiskResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {
        'risk_score': 0.72,
        'risk_level': 'High',
        'recommendation':
            'High fulfillment risk. Adjust ETA and notify merchant.',
      },
    });

    final result = response.toEntity();

    expect(response.success, isTrue);
    expect(response.source, 'ml-service');
    expect(result.riskScore, 0.72);
    expect(result.riskLevel, 'High');
    expect(
      result.recommendation,
      'High fulfillment risk. Adjust ETA and notify merchant.',
    );
    expect(result.source, 'ml-service');
  });

  test('parses a Laravel fallback checkout risk response', () {
    final response = CheckoutRiskResponse.fromJson({
      'success': true,
      'source': 'fallback',
      'data': {
        'risk_score': 0.50,
        'risk_level': 'Unknown',
        'recommendation':
            'Standard checkout allowed. Risk service unavailable.',
      },
    });

    final result = response.toEntity();

    expect(result.riskScore, 0.50);
    expect(result.riskLevel, 'Unknown');
    expect(
      result.recommendation,
      'Standard checkout allowed. Risk service unavailable.',
    );
    expect(result.source, 'fallback');
  });
}

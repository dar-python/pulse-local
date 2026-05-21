import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';

void main() {
  test('parses the Laravel wrapped ml-service risk prediction response', () {
    final response = RiskPredictionResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {
        'risk_score': 0.72,
        'risk_level': 'High',
        'recommendation':
            'High fulfillment risk. Adjust ETA and notify merchant.',
        'eta_range': '40-55 min',
      },
    });

    expect(response.success, isTrue);
    expect(response.source, 'ml-service');
    expect(response.riskScore, 0.72);
    expect(response.riskLevel, 'High');
    expect(response.etaRange, '40-55 min');
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
    expect(response.etaRange, '30-45 min');
  });

  test('normalizes fractional and whole-number risk scores to percentages', () {
    final fractionalResponse = RiskPredictionResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {'risk_score': 0.72, 'risk_level': 'High'},
    });
    final wholeNumberResponse = RiskPredictionResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {'risk_score': 72, 'risk_level': 'High'},
    });

    expect(fractionalResponse.riskPercent, 72);
    expect(wholeNumberResponse.riskPercent, 72);
  });

  test('parses returned checkout weather metadata', () {
    final response = RiskPredictionResponse.fromJson({
      'success': true,
      'source': 'ml-service',
      'data': {
        'risk_score': 0.42,
        'risk_level': 'Medium',
        'weather': {
          'category': 'clear',
          'condition_text': 'Partly cloudy',
          'condition_code': 1003,
          'temperature_c': 30.2,
          'precip_mm': 0,
          'source': 'weatherapi',
          'observed_at': '2026-05-21T10:30:00+08:00',
          'latitude': 14.5995,
          'longitude': 120.9842,
        },
      },
    });

    expect(response.weather?.category, 'clear');
    expect(response.weather?.conditionText, 'Partly cloudy');
    expect(response.weather?.source, 'weatherapi');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';

void main() {
  test('serializes the Sprint 1 Laravel checkout risk request contract', () {
    const request = CheckoutRiskRequest(
      riderToOrderRatio: 0.45,
      merchantPrepTime: 25,
      trafficCorridorIntensity: 'high',
      weatherCategory: 'rainy',
      deliveryDistanceKm: 4.2,
      addressComplexity: 'medium',
      paymentMethod: 'cod',
    );

    final json = request.toJson();

    expect(json, {
      'rider_to_order_ratio': 0.45,
      'merchant_prep_time': 25,
      'traffic_corridor_intensity': 'high',
      'weather_category': 'rainy',
      'delivery_distance_km': 4.2,
      'address_complexity': 'medium',
      'payment_method': 'cod',
    });
    expect(json, isNot(contains('traffic_level')));
    expect(json.values, isNot(contains('heavy')));
    expect(json.values, isNot(contains('moderate')));
    expect(json.values, isNot(contains('light')));
  });
}

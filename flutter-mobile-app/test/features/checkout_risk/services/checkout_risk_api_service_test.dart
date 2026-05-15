import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/services/checkout_risk_api_service.dart';

void main() {
  test('posts the public checkout risk contract to Laravel only', () async {
    final adapter = _CapturingAdapter(
      responseJson: {
        'success': true,
        'source': 'ml-service',
        'data': {
          'risk_score': 0.71,
          'risk_level': 'High',
          'recommendation':
              'High fulfillment risk. Adjust ETA and notify merchant.',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
      ..httpClientAdapter = adapter;
    final service = CheckoutRiskApiService(dio: dio);

    final response = await service.predictRisk(
      const CheckoutRiskRequest(
        riderToOrderRatio: 0.45,
        merchantPrepTime: 25,
        trafficCorridorIntensity: 'high',
        weatherCategory: 'rainy',
        deliveryDistanceKm: 4.2,
        addressComplexity: 'medium',
        paymentMethod: 'cod',
      ),
    );

    expect(adapter.requestOptions?.method, 'POST');
    expect(adapter.requestOptions?.baseUrl, 'http://127.0.0.1:8000');
    expect(adapter.requestOptions?.path, '/api/checkout/risk');
    expect(adapter.requestOptions?.data, {
      'rider_to_order_ratio': 0.45,
      'merchant_prep_time': 25,
      'traffic_corridor_intensity': 'high',
      'weather_category': 'rainy',
      'delivery_distance_km': 4.2,
      'address_complexity': 'medium',
      'payment_method': 'cod',
    });
    expect(response.riskScore, 0.71);
    expect(response.riskLevel, 'High');
    expect(response.source, 'ml-service');
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.responseJson});

  final Map<String, Object?> responseJson;
  RequestOptions? requestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;

    return ResponseBody.fromString(
      jsonEncode(responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

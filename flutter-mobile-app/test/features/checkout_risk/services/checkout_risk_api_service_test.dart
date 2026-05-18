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
          'risk_score': 0.72,
          'risk_level': 'High',
          'recommendation':
              'High fulfillment risk. Adjust ETA and notify merchant.',
          'eta_range': '40-55 min',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
      ..httpClientAdapter = adapter;
    final service = CheckoutRiskApiService(dio: dio);

    final response = await service.predictRisk(
      const CheckoutRiskRequest(
        restaurantId: 1,
        restaurantSlug: 'tambayan-grill',
        items: [
          CheckoutRiskCartItem(
            id: 1,
            name: 'Pork Sinigang',
            category: 'Bestsellers',
            quantity: 1,
            unitPrice: 185,
          ),
        ],
        deliveryAddress: CheckoutRiskDeliveryAddress(
          label: 'Marasbaras, Tacloban City',
          notes: 'Zone 7',
        ),
        paymentMethod: 'cod',
        subtotal: 185,
        totalQuantity: 1,
      ),
    );

    expect(adapter.requestOptions?.method, 'POST');
    expect(adapter.requestOptions?.baseUrl, 'http://127.0.0.1:8000');
    expect(adapter.requestOptions?.path, '/api/checkout/risk');
    expect(adapter.requestOptions?.data, {
      'restaurant_id': 1,
      'restaurant_slug': 'tambayan-grill',
      'items': [
        {
          'id': 1,
          'name': 'Pork Sinigang',
          'category': 'Bestsellers',
          'quantity': 1,
          'unit_price': 185,
        },
      ],
      'delivery_address': {
        'label': 'Marasbaras, Tacloban City',
        'notes': 'Zone 7',
      },
      'payment_method': 'cod',
      'subtotal': 185,
      'total_quantity': 1,
    });
    expect(response.riskScore, 0.72);
    expect(response.riskLevel, 'High');
    expect(response.etaRange, '40-55 min');
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

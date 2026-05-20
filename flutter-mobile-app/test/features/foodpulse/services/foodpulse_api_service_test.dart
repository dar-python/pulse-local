import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/models/cart_item.dart';
import 'package:pulse_local_app/core/models/menu_item.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/services/foodpulse_api_service.dart';

void main() {
  test('loads restaurants from the Laravel local-data API', () async {
    final adapter = _QueueAdapter([
      _JsonResponse({
        'success': true,
        'source': 'local-test-data',
        'data': [
          {
            'id': 1,
            'name': "McDonald's Tacloban",
            'cuisine': 'Filipino - Grills',
            'rating': 4.8,
            'delivery_time': '15-25 min',
            'minimum_order': 99,
            'emoji': 'TG',
            'risk_score': 28,
          },
        ],
      }),
    ]);
    final service = FoodPulseApiService(dio: _dio(adapter));

    final restaurants = await service.fetchRestaurants();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/restaurants');
    expect(restaurants.single.name, "McDonald's Tacloban");
  });

  test('loads menu items for a restaurant from Laravel', () async {
    final adapter = _QueueAdapter([
      _JsonResponse({
        'success': true,
        'source': 'local-test-data',
        'data': {
          'restaurant': {
            'id': 1,
            'name': "McDonald's Tacloban",
            'cuisine': 'Filipino - Grills',
            'rating': 4.8,
            'delivery_time': '15-25 min',
            'minimum_order': 99,
            'emoji': 'TG',
            'risk_score': 28,
          },
          'items': [
            {
              'id': 1,
              'name': 'Pork Sinigang',
              'description': 'Sour tamarind broth',
              'price': 185,
              'emoji': 'PS',
              'category': 'Bestsellers',
            },
          ],
        },
      }),
    ]);
    final service = FoodPulseApiService(dio: _dio(adapter));

    final menu = await service.fetchMenu(1);

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/api/restaurants/1/menu');
    expect(menu.restaurant.name, "McDonald's Tacloban");
    expect(menu.items.single.name, 'Pork Sinigang');
  });

  test(
    'submits cart checkout to Laravel and fetches order confirmation',
    () async {
      final adapter = _QueueAdapter([
        _JsonResponse({
          'success': true,
          'source': 'local-test-data',
          'data': {
            'order_number': 'FP-API-1001',
            'status': 'ready_for_confirmation',
            'restaurant': _restaurantJson(),
            'items': [
              {
                'menu_item_id': 1,
                'name': 'Pork Sinigang',
                'price': 185,
                'quantity': 1,
                'line_total': 185,
              },
            ],
            'payment_method': 'cod',
            'delivery_address': {'label': 'Marasbaras'},
            'subtotal': 185,
            'delivery_fee': 49,
            'service_charge': 10,
            'total': 244,
            'risk': _riskJson(),
          },
        }),
        _JsonResponse({
          'success': true,
          'source': 'local-test-data',
          'data': {
            'order_number': 'FP-API-1001',
            'status': 'confirmed',
            'estimated_arrival': '25-35 min',
            'restaurant': _restaurantJson(),
            'items': [],
            'payment_method': 'cod',
            'delivery_address': {'label': 'Marasbaras'},
            'subtotal': 185,
            'delivery_fee': 49,
            'service_charge': 10,
            'total': 244,
            'risk': _riskJson(),
            'tracking_steps': [
              {'label': 'Order placed', 'done': true},
            ],
          },
        }),
      ]);
      final service = FoodPulseApiService(dio: _dio(adapter));

      final checkout = await service.checkoutCart(
        restaurant: Restaurant.fromJson(_restaurantJson()),
        items: [
          CartItem(item: MenuItem.fromJson(_menuItemJson()), quantity: 1),
        ],
        paymentMethod: 'cod',
        deliveryAddress: const FoodPulseDeliveryAddress(
          label: 'Marasbaras',
          notes: 'Zone 7',
        ),
      );
      final confirmation = await service.fetchOrderConfirmation(
        checkout.orderNumber,
      );

      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.first.path, '/api/cart/checkout');
      expect(adapter.requests.first.data, {
        'restaurant_id': 1,
        'items': [
          {'menu_item_id': 1, 'quantity': 1},
        ],
        'payment_method': 'cod',
        'delivery_address': {'label': 'Marasbaras', 'notes': 'Zone 7'},
      });
      expect(adapter.requests.last.method, 'GET');
      expect(
        adapter.requests.last.path,
        '/api/orders/FP-API-1001/confirmation',
      );
      expect(confirmation.orderNumber, 'FP-API-1001');
      expect(confirmation.estimatedArrival, '25-35 min');
    },
  );
}

Dio _dio(_QueueAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'))
    ..httpClientAdapter = adapter;
}

Map<String, Object?> _restaurantJson() {
  return {
    'id': 1,
    'name': "McDonald's Tacloban",
    'cuisine': 'Filipino - Grills',
    'rating': 4.8,
    'delivery_time': '15-25 min',
    'minimum_order': 99,
    'emoji': 'TG',
    'risk_score': 28,
  };
}

Map<String, Object?> _menuItemJson() {
  return {
    'id': 1,
    'name': 'Pork Sinigang',
    'description': 'Sour tamarind broth',
    'price': 185,
    'emoji': 'PS',
    'category': 'Bestsellers',
  };
}

Map<String, Object?> _riskJson() {
  return {
    'risk_score': 68,
    'risk_level': 'Medium',
    'recommendation': 'Medium fulfillment risk. Keep ETA visible.',
  };
}

class _JsonResponse {
  const _JsonResponse(this.body);

  final Map<String, Object?> body;
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.responses);

  final List<_JsonResponse> responses;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses.removeAt(0);

    return ResponseBody.fromString(
      jsonEncode(response.body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

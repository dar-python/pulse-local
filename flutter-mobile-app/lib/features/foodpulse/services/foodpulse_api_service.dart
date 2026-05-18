import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/restaurant.dart';
import '../../../core/network/api_exception.dart';
import '../models/foodpulse_order.dart';

class FoodPulseApiService {
  FoodPulseApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.laravelBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  Future<List<Restaurant>> fetchRestaurants() async {
    final payload = await _get('/api/restaurants');
    final data = payload['data'];
    if (data is! List) {
      throw const ApiException('Laravel restaurants response was invalid.');
    }

    return data
        .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RestaurantMenu> fetchMenu(int restaurantId) async {
    final payload = await _get('/api/restaurants/$restaurantId/menu');
    return RestaurantMenu.fromJson(payload);
  }

  Future<CheckoutSummary> checkoutCart({
    required Restaurant restaurant,
    required List<CartItem> items,
    required String paymentMethod,
    required FoodPulseDeliveryAddress deliveryAddress,
  }) async {
    final request = CheckoutCartRequest(
      restaurant: restaurant,
      items: items,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
    );
    final payload = await _post('/api/cart/checkout', data: request.toJson());

    return CheckoutSummary.fromJson(payload);
  }

  Future<OrderConfirmation> fetchOrderConfirmation(String orderNumber) async {
    final payload = await _get('/api/orders/$orderNumber/confirmation');
    return OrderConfirmation.fromJson(payload);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return _validatedPayload(response);
    } on DioException catch (error) {
      throw ApiException(
        _messageForDioError(error),
        statusCode: error.response?.statusCode,
      );
    } on TypeError {
      throw const ApiException('Laravel local-data response was invalid.');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Object data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return _validatedPayload(response);
    } on DioException catch (error) {
      throw ApiException(
        _messageForDioError(error),
        statusCode: error.response?.statusCode,
      );
    } on TypeError {
      throw const ApiException('Laravel local-data response was invalid.');
    }
  }

  Map<String, dynamic> _validatedPayload(
    Response<Map<String, dynamic>> response,
  ) {
    final payload = response.data;
    if (payload == null || payload['success'] != true) {
      throw ApiException(
        'Laravel local-data API returned an unsuccessful response.',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  String _messageForDioError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return 'Laravel local-data API cannot be reached.';
  }
}

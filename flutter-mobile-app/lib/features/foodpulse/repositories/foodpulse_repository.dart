import 'package:flutter/widgets.dart';

import '../../../core/data/mock_foodpulse_data.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/restaurant.dart';
import '../models/foodpulse_order.dart';
import '../services/foodpulse_api_service.dart';

class FoodPulseResult<T> {
  const FoodPulseResult({
    required this.data,
    required this.usedFallback,
    this.message,
  });

  factory FoodPulseResult.data(T data) {
    return FoodPulseResult(data: data, usedFallback: false);
  }

  factory FoodPulseResult.fallback(T data, {required String message}) {
    return FoodPulseResult(data: data, usedFallback: true, message: message);
  }

  final T data;
  final bool usedFallback;
  final String? message;
}

abstract class FoodPulseRepository {
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants();

  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId);

  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  );

  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  );
}

class LaravelFoodPulseRepository implements FoodPulseRepository {
  LaravelFoodPulseRepository({
    FoodPulseApiService? service,
    FoodPulseFallbackRepository? fallbackRepository,
  }) : _service = service ?? FoodPulseApiService(),
       _fallbackRepository =
           fallbackRepository ?? const FoodPulseFallbackRepository();

  final FoodPulseApiService _service;
  final FoodPulseFallbackRepository _fallbackRepository;

  @override
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants() async {
    try {
      return FoodPulseResult.data(await _service.fetchRestaurants());
    } catch (_) {
      return FoodPulseResult.fallback(
        _fallbackRepository.restaurants(),
        message: 'Using saved local restaurant data.',
      );
    }
  }

  @override
  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId) async {
    try {
      return FoodPulseResult.data(await _service.fetchMenu(restaurantId));
    } catch (_) {
      return FoodPulseResult.fallback(
        _fallbackRepository.menu(restaurantId),
        message: 'Using saved local menu data.',
      );
    }
  }

  @override
  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  ) async {
    try {
      return FoodPulseResult.data(
        await _service.checkoutCart(
          restaurant: request.restaurant,
          items: request.items,
          paymentMethod: request.paymentMethod,
          deliveryAddress: request.deliveryAddress,
        ),
      );
    } catch (_) {
      return FoodPulseResult.fallback(
        _fallbackRepository.checkout(request),
        message: 'Using saved local checkout data.',
      );
    }
  }

  @override
  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  ) async {
    try {
      return FoodPulseResult.data(
        await _service.fetchOrderConfirmation(orderNumber),
      );
    } catch (_) {
      return FoodPulseResult.fallback(
        _fallbackRepository.orderConfirmation(orderNumber),
        message: 'Using saved local order confirmation.',
      );
    }
  }
}

class FoodPulseFallbackRepository {
  const FoodPulseFallbackRepository();

  List<Restaurant> restaurants() {
    return MockFoodPulseData.restaurants;
  }

  RestaurantMenu menu(int restaurantId) {
    final restaurant = _restaurantById(restaurantId);

    return RestaurantMenu(
      restaurant: restaurant,
      items: MockFoodPulseData.menuItemsFor(restaurant.id),
    );
  }

  CheckoutSummary checkout(CheckoutCartRequest request) {
    final subtotal = MockFoodPulseData.subtotalFor(request.items);

    return CheckoutSummary(
      orderNumber: MockFoodPulseData.orderNumber,
      status: 'ready_for_confirmation',
      restaurant: request.restaurant,
      items: _orderItems(request.items),
      paymentMethod: request.paymentMethod,
      subtotal: subtotal,
      deliveryFee: MockFoodPulseData.deliveryFee,
      serviceCharge: MockFoodPulseData.serviceCharge,
      total:
          subtotal +
          MockFoodPulseData.deliveryFee +
          MockFoodPulseData.serviceCharge,
      risk: const FoodPulseOrderRisk(
        score: MockFoodPulseData.checkoutRiskScore,
        level: 'Medium',
        recommendation: 'Medium fulfillment risk. Keep ETA visible.',
      ),
    );
  }

  OrderConfirmation orderConfirmation(String orderNumber) {
    final checkoutSummary = checkout(
      CheckoutCartRequest(
        restaurant: MockFoodPulseData.restaurants.first,
        items: MockFoodPulseData.defaultCart,
        paymentMethod: 'cod',
        deliveryAddress: const FoodPulseDeliveryAddress(
          label: 'Marasbaras, Tacloban City',
          notes: 'Zone 7, Leyte, Philippines',
        ),
      ),
    );

    return OrderConfirmation(
      orderNumber: orderNumber.isEmpty
          ? MockFoodPulseData.orderNumber
          : orderNumber,
      status: 'confirmed',
      estimatedArrival: '30-45 min',
      restaurant: checkoutSummary.restaurant,
      items: checkoutSummary.items,
      paymentMethod: checkoutSummary.paymentMethod,
      subtotal: checkoutSummary.subtotal,
      deliveryFee: checkoutSummary.deliveryFee,
      serviceCharge: checkoutSummary.serviceCharge,
      total: checkoutSummary.total,
      risk: checkoutSummary.risk,
      trackingSteps: const [
        FoodPulseTrackingStep(label: 'Order placed', done: true),
        FoodPulseTrackingStep(label: 'Merchant preparing', done: true),
        FoodPulseTrackingStep(label: 'Rider assigned', done: false),
        FoodPulseTrackingStep(label: 'Out for delivery', done: false),
      ],
    );
  }

  Restaurant _restaurantById(int restaurantId) {
    return MockFoodPulseData.restaurants.firstWhere(
      (restaurant) => restaurant.id == restaurantId,
      orElse: () => MockFoodPulseData.restaurants.first,
    );
  }

  List<FoodPulseOrderItem> _orderItems(List<CartItem> cartItems) {
    return cartItems
        .map(
          (cartItem) => FoodPulseOrderItem(
            menuItemId: cartItem.item.id,
            name: cartItem.item.name,
            price: cartItem.item.price,
            quantity: cartItem.quantity,
            lineTotal: cartItem.lineTotal,
          ),
        )
        .toList();
  }
}

class FoodPulseRepositoryScope extends InheritedWidget {
  const FoodPulseRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final FoodPulseRepository repository;

  static FoodPulseRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FoodPulseRepositoryScope>()
        ?.repository;
  }

  @override
  bool updateShouldNotify(FoodPulseRepositoryScope oldWidget) {
    return oldWidget.repository != repository;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/features/cart/cart_screen.dart';
import 'package:pulse_local_app/features/checkout/checkout_screen.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';
import 'package:pulse_local_app/features/home/home_screen.dart';
import 'package:pulse_local_app/features/order/confirmed_screen.dart';
import 'package:pulse_local_app/features/restaurant/restaurant_screen.dart';

void main() {
  testWidgets('home shows an empty state when no restaurants are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          restaurantsHandler: () async => FoodPulseResult.data(const []),
        ),
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No restaurants available right now.'), findsOneWidget);
    expect(find.text('Tambayan Grill'), findsNothing);
  });

  testWidgets(
    'restaurant shows an empty state when no menu items are returned',
    (tester) async {
      await tester.pumpWidget(
        _wrapped(
          repository: _FakeFoodPulseRepository(
            menuHandler: (_) async => FoodPulseResult.data(
              RestaurantMenu(
                restaurant: MockFoodPulseData.restaurants.first,
                items: const [],
              ),
            ),
          ),
          child: RestaurantScreen(
            restaurant: MockFoodPulseData.restaurants.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No menu items are available right now.'),
        findsOneWidget,
      );
      expect(find.text('View Cart'), findsNothing);
    },
  );

  testWidgets('cart and checkout validate empty carts', (tester) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(),
        child: CartScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: const [],
        ),
      ),
    );

    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(find.textContaining('Proceed to Checkout'), findsNothing);

    final repository = _FakeFoodPulseRepository();
    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.medium(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: const [],
          checkoutRiskRepository: const _StaticRiskRepository.medium(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Add at least one item before checkout.'), findsOneWidget);
    expect(repository.checkoutRequests, isEmpty);
  });

  testWidgets('checkout validates missing delivery address before submission', (
    tester,
  ) async {
    final repository = _FakeFoodPulseRepository();

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.medium(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          deliveryAddress: const FoodPulseDeliveryAddress(label: ''),
          checkoutRiskRepository: const _StaticRiskRepository.medium(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a delivery address before placing your order.'),
      findsOneWidget,
    );
    expect(repository.checkoutRequests, isEmpty);
  });

  testWidgets('checkout shows order and confirmation loading states', (
    tester,
  ) async {
    final checkoutCompleter = Completer<FoodPulseResult<CheckoutSummary>>();
    final confirmationCompleter =
        Completer<FoodPulseResult<OrderConfirmation>>();
    final repository = _FakeFoodPulseRepository(
      checkoutHandler: (_) => checkoutCompleter.future,
      confirmationHandler: (_) => confirmationCompleter.future,
    );

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.medium(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.medium(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pump();

    expect(find.text('Placing Order...'), findsOneWidget);

    checkoutCompleter.complete(FoodPulseResult.data(_checkout('FP-LOADING-1')));
    await tester.pump();

    expect(find.text('Loading confirmation...'), findsOneWidget);

    confirmationCompleter.complete(
      FoodPulseResult.data(_confirmation('FP-LOADING-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order #FP-LOADING-1'), findsOneWidget);
  });

  testWidgets('checkout submission failure uses a friendly fallback state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          checkoutHandler: (_) async => throw Exception('socket closed'),
        ),
        riskRepository: const _StaticRiskRepository.medium(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.medium(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(
      find.textContaining('Using saved local checkout data'),
      findsOneWidget,
    );
    expect(find.textContaining('socket closed'), findsNothing);
  });

  testWidgets('high risk shows a confirmation modal before checkout', (
    tester,
  ) async {
    final repository = _FakeFoodPulseRepository();

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.high(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.high(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('High fulfillment risk'), findsWidgets);
    expect(find.textContaining('detected before checkout'), findsOneWidget);
    expect(find.text('Continue Order'), findsOneWidget);
    expect(repository.checkoutRequests, isEmpty);

    await tester.tap(find.text('Continue Order'));
    await tester.pumpAndSettle();

    expect(repository.checkoutRequests, hasLength(1));
    expect(find.text('Order Confirmed!'), findsOneWidget);
  });

  testWidgets('high checkout risk remains high on confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          checkoutHandler: (_) async => FoodPulseResult.data(
            _checkout(
              'FP-HIGH-RISK',
              risk: const FoodPulseOrderRisk(
                score: 68,
                level: 'Medium',
                recommendation: 'Medium fulfillment risk. Keep ETA visible.',
              ),
            ),
          ),
          confirmationHandler: (_) async => FoodPulseResult.data(
            _confirmation(
              'FP-HIGH-RISK',
              risk: const FoodPulseOrderRisk(
                score: 68,
                level: 'Medium',
                recommendation: 'Medium fulfillment risk. Keep ETA visible.',
              ),
            ),
          ),
        ),
        riskRepository: const _StaticRiskRepository.high(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.high(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue Order'));
    await tester.pumpAndSettle();

    expect(find.text('82% - adjusting ETA'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsOneWidget);
  });

  testWidgets('medium checkout risk remains medium on confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          checkoutHandler: (_) async => FoodPulseResult.data(
            _checkout(
              'FP-MEDIUM-RISK',
              risk: const FoodPulseOrderRisk(
                score: 68,
                level: 'Medium',
                recommendation: 'Medium fulfillment risk. Keep ETA visible.',
              ),
            ),
          ),
          confirmationHandler: (_) async => FoodPulseResult.data(
            _confirmation(
              'FP-MEDIUM-RISK',
              risk: const FoodPulseOrderRisk(
                score: 68,
                level: 'Medium',
                recommendation: 'Medium fulfillment risk. Keep ETA visible.',
              ),
            ),
          ),
        ),
        riskRepository: const _StaticRiskRepository.medium52(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.medium52(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('52% - adjusting ETA'), findsOneWidget);
    expect(find.text('MEDIUM RISK'), findsOneWidget);
  });

  testWidgets('fallback risk still allows checkout', (tester) async {
    final repository = _FakeFoodPulseRepository();

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.fallback(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.fallback(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(repository.checkoutRequests, hasLength(1));
    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(find.text('50% - adjusting ETA'), findsOneWidget);
    expect(find.text('UNKNOWN RISK'), findsOneWidget);
  });

  testWidgets('place order cannot be double tapped while submitting', (
    tester,
  ) async {
    final checkoutCompleter = Completer<FoodPulseResult<CheckoutSummary>>();
    final repository = _FakeFoodPulseRepository(
      checkoutHandler: (_) => checkoutCompleter.future,
    );

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        riskRepository: const _StaticRiskRepository.medium(),
        child: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          items: MockFoodPulseData.defaultCart,
          checkoutRiskRepository: const _StaticRiskRepository.medium(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final placeOrderButton = find.textContaining('Place Order');
    await tester.ensureVisible(placeOrderButton);
    await tester.tap(placeOrderButton);
    await tester.tap(placeOrderButton);
    await tester.pump();

    expect(repository.checkoutRequests, hasLength(1));
    expect(find.text('Placing Order...'), findsOneWidget);

    checkoutCompleter.complete(
      FoodPulseResult.data(_checkout('FP-DOUBLE-TAP')),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('confirmation screen handles missing order confirmation safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmedScreen(
          orderConfirmation: OrderConfirmation(
            orderNumber: '',
            status: 'missing',
            estimatedArrival: '',
            restaurant: Restaurant(
              id: 1,
              name: 'Tambayan Grill',
              cuisine: 'Filipino',
              rating: 4.8,
              deliveryTime: '15-25 min',
              minimumOrder: 99,
              emoji: 'TG',
              riskScore: 28,
            ),
            items: [],
            paymentMethod: 'cod',
            subtotal: 0,
            deliveryFee: 0,
            serviceCharge: 0,
            total: 0,
            risk: FoodPulseOrderRisk(
              score: 0,
              level: 'Unknown',
              recommendation: 'No confirmation was returned.',
            ),
            trackingSteps: [],
          ),
        ),
      ),
    );

    expect(find.text('Order confirmation is unavailable.'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });
}

Widget _wrapped({
  required FoodPulseRepository repository,
  FoodPulseCheckoutRiskRepository riskRepository =
      const _StaticRiskRepository.medium(),
  required Widget child,
}) {
  return MaterialApp(
    home: FoodPulseRepositoryScope(
      repository: repository,
      child: FoodPulseCheckoutRiskScope(
        repository: riskRepository,
        child: child,
      ),
    ),
  );
}

CheckoutSummary _checkout(
  String orderNumber, {
  FoodPulseOrderRisk risk = const FoodPulseOrderRisk(
    score: 68,
    level: 'Medium',
    recommendation: 'Medium fulfillment risk. Keep ETA visible.',
  ),
}) {
  return CheckoutSummary(
    orderNumber: orderNumber,
    status: 'ready_for_confirmation',
    restaurant: MockFoodPulseData.restaurants.first,
    items: const [
      FoodPulseOrderItem(
        menuItemId: 1,
        name: 'Pork Sinigang',
        price: 185,
        quantity: 1,
        lineTotal: 185,
      ),
    ],
    paymentMethod: 'cod',
    subtotal: 185,
    deliveryFee: 49,
    serviceCharge: 10,
    total: 244,
    risk: risk,
  );
}

OrderConfirmation _confirmation(
  String orderNumber, {
  FoodPulseOrderRisk risk = const FoodPulseOrderRisk(
    score: 68,
    level: 'Medium',
    recommendation: 'Medium fulfillment risk. Keep ETA visible.',
  ),
}) {
  return OrderConfirmation(
    orderNumber: orderNumber,
    status: 'confirmed',
    estimatedArrival: '25-35 min',
    restaurant: MockFoodPulseData.restaurants.first,
    items: const [],
    paymentMethod: 'cod',
    subtotal: 185,
    deliveryFee: 49,
    serviceCharge: 10,
    total: 244,
    risk: risk,
    trackingSteps: const [
      FoodPulseTrackingStep(label: 'Order placed', done: true),
    ],
  );
}

class _FakeFoodPulseRepository implements FoodPulseRepository {
  _FakeFoodPulseRepository({
    this.restaurantsHandler,
    this.menuHandler,
    this.checkoutHandler,
    this.confirmationHandler,
  });

  final Future<FoodPulseResult<List<Restaurant>>> Function()?
  restaurantsHandler;
  final Future<FoodPulseResult<RestaurantMenu>> Function(int restaurantId)?
  menuHandler;
  final Future<FoodPulseResult<CheckoutSummary>> Function(
    CheckoutCartRequest request,
  )?
  checkoutHandler;
  final Future<FoodPulseResult<OrderConfirmation>> Function(String orderNumber)?
  confirmationHandler;
  final List<CheckoutCartRequest> checkoutRequests = [];
  final List<String> confirmationRequests = [];

  @override
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants() {
    return restaurantsHandler?.call() ??
        Future.value(FoodPulseResult.data(MockFoodPulseData.restaurants));
  }

  @override
  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId) {
    return menuHandler?.call(restaurantId) ??
        Future.value(
          FoodPulseResult.data(
            RestaurantMenu(
              restaurant: MockFoodPulseData.restaurants.first,
              items: MockFoodPulseData.menuItems,
            ),
          ),
        );
  }

  @override
  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  ) {
    checkoutRequests.add(request);
    return checkoutHandler?.call(request) ??
        Future.value(FoodPulseResult.data(_checkout('FP-2024-9873')));
  }

  @override
  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  ) {
    confirmationRequests.add(orderNumber);
    return confirmationHandler?.call(orderNumber) ??
        Future.value(FoodPulseResult.data(_confirmation(orderNumber)));
  }
}

class _StaticRiskRepository implements FoodPulseCheckoutRiskRepository {
  const _StaticRiskRepository._(this.response);

  const _StaticRiskRepository.medium()
    : this._(
        const RiskPredictionResponse(
          success: true,
          source: 'ml-service',
          riskScore: 0.68,
          riskLevel: 'Medium',
          recommendation: 'Medium fulfillment risk. Keep ETA visible.',
        ),
      );

  const _StaticRiskRepository.medium52()
    : this._(
        const RiskPredictionResponse(
          success: true,
          source: 'ml-service',
          riskScore: 0.52,
          riskLevel: 'Medium',
          recommendation: 'Medium fulfillment risk. Keep ETA visible.',
        ),
      );

  const _StaticRiskRepository.high()
    : this._(
        const RiskPredictionResponse(
          success: true,
          source: 'ml-service',
          riskScore: 0.82,
          riskLevel: 'High',
          recommendation:
              'High fulfillment risk. Adjust ETA and notify merchant.',
        ),
      );

  const _StaticRiskRepository.fallback()
    : this._(
        const RiskPredictionResponse(
          success: true,
          source: 'laravel-fallback',
          riskScore: 0.50,
          riskLevel: 'Unknown',
          recommendation:
              'Prediction service unavailable. Proceed with standard checkout risk.',
        ),
      );

  final RiskPredictionResponse response;

  @override
  Future<RiskPredictionResponse> predictRisk(
    CheckoutRiskRequest request,
  ) async {
    return response;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/menu_item.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/features/checkout/checkout_screen.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';
import 'package:pulse_local_app/features/home/home_screen.dart';
import 'package:pulse_local_app/features/restaurant/restaurant_screen.dart';

void main() {
  testWidgets('home renders restaurants loaded from the repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          restaurantsResult: FoodPulseResult.data([
            const Restaurant(
              id: 7,
              name: 'Leyte Bowls',
              cuisine: 'Rice Meals',
              rating: 4.7,
              deliveryTime: '12-20 min',
              minimumOrder: 120,
              emoji: 'LB',
              riskScore: 35,
            ),
          ]),
        ),
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leyte Bowls'), findsOneWidget);
    expect(find.text('Tambayan Grill'), findsNothing);
  });

  testWidgets('restaurant screen renders menu loaded from the repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          menuResult: FoodPulseResult.data(
            RestaurantMenu(
              restaurant: MockFoodPulseData.restaurants.first,
              items: const [
                MenuItem(
                  id: 50,
                  name: 'Remote Adobo',
                  description: 'Soy garlic chicken',
                  price: 199,
                  emoji: 'RA',
                  category: 'Bestsellers',
                ),
              ],
            ),
          ),
        ),
        child: RestaurantScreen(
          restaurant: MockFoodPulseData.restaurants.first,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remote Adobo'), findsOneWidget);
    expect(find.text('Pork Sinigang'), findsNothing);
  });

  testWidgets(
    'checkout submits cart and displays returned order confirmation',
    (tester) async {
      final repository = _FakeFoodPulseRepository(
        checkoutResult: FoodPulseResult.data(_checkout('FP-API-1001')),
        confirmationResult: FoodPulseResult.data(
          _confirmation('FP-API-1001', estimatedArrival: '25-35 min'),
        ),
      );

      await tester.pumpWidget(
        _wrapped(
          repository: repository,
          child: CheckoutScreen(
            restaurant: MockFoodPulseData.restaurants.first,
            items: MockFoodPulseData.defaultCart,
            checkoutRiskRepository: const _StaticRiskRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('Place Order'));
      await tester.tap(find.textContaining('Place Order'));
      await tester.pumpAndSettle();

      expect(repository.checkoutRequests.single.paymentMethod, 'cod');
      expect(repository.confirmationRequests.single, 'FP-API-1001');
      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('Order #FP-API-1001'), findsOneWidget);
      expect(find.text('Est. Arrival: 25-35 min'), findsOneWidget);
    },
  );

  testWidgets('API fallback state keeps the UI usable', (tester) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          restaurantsResult: FoodPulseResult.fallback(
            MockFoodPulseData.restaurants,
            message: 'Using saved local restaurant data.',
          ),
        ),
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambayan Grill'), findsOneWidget);
    expect(find.text('Using saved local restaurant data.'), findsOneWidget);
  });
}

Widget _wrapped({
  required FoodPulseRepository repository,
  required Widget child,
}) {
  return MaterialApp(
    home: FoodPulseRepositoryScope(repository: repository, child: child),
  );
}

CheckoutSummary _checkout(String orderNumber) {
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
    risk: const FoodPulseOrderRisk(
      score: 68,
      level: 'Medium',
      recommendation: 'Medium fulfillment risk. Keep ETA visible.',
    ),
  );
}

OrderConfirmation _confirmation(
  String orderNumber, {
  String estimatedArrival = '30-45 min',
}) {
  return OrderConfirmation(
    orderNumber: orderNumber,
    status: 'confirmed',
    estimatedArrival: estimatedArrival,
    restaurant: MockFoodPulseData.restaurants.first,
    items: const [],
    paymentMethod: 'cod',
    subtotal: 185,
    deliveryFee: 49,
    serviceCharge: 10,
    total: 244,
    risk: const FoodPulseOrderRisk(
      score: 68,
      level: 'Medium',
      recommendation: 'Medium fulfillment risk. Keep ETA visible.',
    ),
    trackingSteps: const [
      FoodPulseTrackingStep(label: 'Order placed', done: true),
    ],
  );
}

class _FakeFoodPulseRepository implements FoodPulseRepository {
  _FakeFoodPulseRepository({
    FoodPulseResult<List<Restaurant>>? restaurantsResult,
    FoodPulseResult<RestaurantMenu>? menuResult,
    FoodPulseResult<CheckoutSummary>? checkoutResult,
    FoodPulseResult<OrderConfirmation>? confirmationResult,
  }) : restaurantsResult =
           restaurantsResult ??
           FoodPulseResult.data(MockFoodPulseData.restaurants),
       menuResult =
           menuResult ??
           FoodPulseResult.data(
             RestaurantMenu(
               restaurant: MockFoodPulseData.restaurants.first,
               items: MockFoodPulseData.menuItems,
             ),
           ),
       checkoutResult =
           checkoutResult ?? FoodPulseResult.data(_checkout('FP-2024-9873')),
       confirmationResult =
           confirmationResult ??
           FoodPulseResult.data(_confirmation('FP-2024-9873'));

  final FoodPulseResult<List<Restaurant>> restaurantsResult;
  final FoodPulseResult<RestaurantMenu> menuResult;
  final FoodPulseResult<CheckoutSummary> checkoutResult;
  final FoodPulseResult<OrderConfirmation> confirmationResult;
  final List<CheckoutCartRequest> checkoutRequests = [];
  final List<String> confirmationRequests = [];

  @override
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants() async {
    return restaurantsResult;
  }

  @override
  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId) async {
    return menuResult;
  }

  @override
  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  ) async {
    checkoutRequests.add(request);
    return checkoutResult;
  }

  @override
  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  ) async {
    confirmationRequests.add(orderNumber);
    return confirmationResult;
  }
}

class _StaticRiskRepository implements FoodPulseCheckoutRiskRepository {
  const _StaticRiskRepository();

  @override
  Future<RiskPredictionResponse> predictRisk(
    CheckoutRiskRequest request,
  ) async {
    return const RiskPredictionResponse(
      success: true,
      source: 'ml-service',
      riskScore: 0.68,
      riskLevel: 'Medium',
      recommendation: 'Medium fulfillment risk. Keep ETA visible.',
    );
  }
}

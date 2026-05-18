import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/cart_item.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/core/network/api_exception.dart';
import 'package:pulse_local_app/features/checkout/checkout_screen.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';

void main() {
  testWidgets('loads the Laravel prediction with current checkout context', (
    tester,
  ) async {
    final completer = Completer<RiskPredictionResponse>();
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          key: const ValueKey('jollibee-checkout'),
          restaurant: MockFoodPulseData.restaurants[1],
          items: const [
            CartItem(item: MockFoodPulseData.chickenjoyMeal, quantity: 1),
          ],
          deliveryAddress: FoodPulseDeliveryAddress(
            label: 'Tacloban City',
            notes: 'Near downtown',
          ),
          initialPaymentMethod: 'gcash',
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    completer.complete(
      const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 0.68,
        riskLevel: 'Medium',
        recommendation: 'Medium fulfillment risk. Keep ETA visible.',
        etaRange: '30-40 min',
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requests.single.toJson(), {
      'restaurant_id': 2,
      'restaurant_slug': 'jollibee-express',
      'items': [
        {
          'id': 6,
          'name': 'Chickenjoy Meal',
          'category': 'Bestsellers',
          'quantity': 1,
          'unit_price': 149,
        },
      ],
      'delivery_address': {'label': 'Tacloban City', 'notes': 'Near downtown'},
      'payment_method': 'gcash',
      'subtotal': 149,
      'total_quantity': 1,
    });
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('MEDIUM RISK'), findsWidgets);
    expect(
      find.text('Medium fulfillment risk. Keep ETA visible.'),
      findsWidgets,
    );
  });

  testWidgets('normalizes whole-number Laravel scores and displays high risk', (
    tester,
  ) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async => const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 72,
        riskLevel: 'High',
        recommendation:
            'High fulfillment risk. Adjust ETA and notify merchant.',
        etaRange: '40-55 min',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('72%'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsWidgets);
    expect(
      find.text('High fulfillment risk. Adjust ETA and notify merchant.'),
      findsWidgets,
    );
  });

  testWidgets('displays the Laravel fallback unknown risk response', (
    tester,
  ) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async => const RiskPredictionResponse(
        success: true,
        source: 'laravel-fallback',
        riskScore: 0.50,
        riskLevel: 'Unknown',
        recommendation: 'Standard checkout allowed. Risk service unavailable.',
        etaRange: '30-45 min',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('UNKNOWN RISK'), findsWidgets);
    expect(
      find.text('Fallback risk mode active. You can still place your order.'),
      findsOneWidget,
    );
    expect(find.textContaining('laravel-fallback'), findsNothing);
  });

  testWidgets('different restaurant carts trigger different risk payloads', (
    tester,
  ) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async => const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 0.30,
        riskLevel: 'Low',
        recommendation: 'Low fulfillment risk. Proceed with normal checkout.',
        etaRange: '20-30 min',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          restaurant: MockFoodPulseData.restaurants[1],
          items: const [
            CartItem(item: MockFoodPulseData.chickenjoyMeal, quantity: 1),
          ],
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          key: const ValueKey('chao-fan-checkout'),
          restaurant: MockFoodPulseData.restaurants[2],
          items: const [
            CartItem(item: MockFoodPulseData.porkChaoFan, quantity: 2),
            CartItem(item: MockFoodPulseData.siomai, quantity: 2),
          ],
          deliveryAddress: FoodPulseDeliveryAddress(
            label: 'V&G Subdivision Extension',
          ),
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
    expect(
      repository.requests[0].toJson(),
      isNot(repository.requests[1].toJson()),
    );
    expect(repository.requests[0].toJson()['restaurant_id'], 2);
    expect(repository.requests[1].toJson()['restaurant_id'], 3);
    expect(repository.requests[1].toJson()['total_quantity'], 4);
  });

  testWidgets('keeps checkout confirmation available when the API fails', (
    tester,
  ) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async {
        throw const ApiException(
          'Laravel checkout risk API cannot be reached.',
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Risk prediction is unavailable right now. You can still place your order.',
      ),
      findsOneWidget,
    );

    final placeOrderButton = find.textContaining('Place Order');
    await tester.ensureVisible(placeOrderButton);
    await tester.tap(placeOrderButton);
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed!'), findsOneWidget);
  });

  testWidgets('risk card shows only top delay reasons', (tester) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async => const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 0.85,
        riskLevel: 'High',
        recommendation: 'High fulfillment risk. Adjust ETA.',
        etaRange: '40-55 min',
        advisoryMessage:
            'Possible delay because of heavy traffic and bad weather.',
        advisoryReasons: [
          RiskAdvisoryReason(
            code: 'heavy_traffic',
            label: 'Heavy traffic may delay the rider.',
          ),
          RiskAdvisoryReason(
            code: 'rainy_weather',
            label: 'Bad weather may slow down delivery.',
          ),
          RiskAdvisoryReason(code: 'merchant_ready', label: 'Merchant ready.'),
          RiskAdvisoryReason(
            code: 'long_preparation',
            label: 'This order may take longer to prepare.',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heavy traffic may delay the rider.'), findsOneWidget);
    expect(find.text('Bad weather may slow down delivery.'), findsOneWidget);
    expect(find.text('Merchant ready.'), findsNothing);
    expect(find.text('This order may take longer to prepare.'), findsNothing);
    expect(find.text('High rider pressure'), findsNothing);
    expect(find.text('Merchant ready'), findsNothing);
  });

  testWidgets(
    'confirmation keeps checkout risk and eta when confirmation eta is default',
    (tester) async {
      final repository = _FakeFoodPulseCheckoutRiskRepository(
        onPredictRisk: (_) async => const RiskPredictionResponse(
          success: true,
          source: 'ml-service',
          riskScore: 0.68,
          riskLevel: 'Medium',
          recommendation: 'Medium fulfillment risk. Show realistic ETA.',
          etaRange: '30-40 min',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            checkoutRiskRepository: repository,
            foodPulseRepository: const _StaticFoodPulseRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final placeOrderButton = find.textContaining('Place Order');
      await tester.ensureVisible(placeOrderButton);
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();

      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('Est. Arrival: 30-40 min'), findsOneWidget);
      expect(find.text('68% - adjusting ETA'), findsOneWidget);
    },
  );

  testWidgets('confirmation preserves simplified checkout advisory', (
    tester,
  ) async {
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) async => const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 0.68,
        riskLevel: 'Medium',
        recommendation: 'Medium fulfillment risk. Show realistic ETA.',
        etaRange: '30-40 min',
        advisoryMessage:
            'Possible delay because of moderate traffic and peak-hour timing.',
        advisoryReasons: [
          RiskAdvisoryReason(
            code: 'medium_traffic',
            label: 'Moderate traffic may slightly affect delivery time.',
          ),
          RiskAdvisoryReason(
            code: 'peak_hour',
            label: 'Peak-hour timing may affect delivery speed.',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          checkoutRiskRepository: repository,
          foodPulseRepository: const _StaticFoodPulseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final placeOrderButton = find.textContaining('Place Order');
    await tester.ensureVisible(placeOrderButton);
    await tester.tap(placeOrderButton);
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(
      find.text(
        'Possible delay because of moderate traffic and peak-hour timing.',
      ),
      findsOneWidget,
    );
  });
}

class _StaticFoodPulseRepository implements FoodPulseRepository {
  const _StaticFoodPulseRepository();

  @override
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants() async {
    return FoodPulseResult.data(MockFoodPulseData.restaurants);
  }

  @override
  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId) async {
    return FoodPulseResult.data(
      RestaurantMenu(
        restaurant: MockFoodPulseData.restaurants.first,
        items: MockFoodPulseData.menuItems,
      ),
    );
  }

  @override
  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  ) async {
    return FoodPulseResult.data(
      const FoodPulseFallbackRepository().checkout(request),
    );
  }

  @override
  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  ) async {
    return FoodPulseResult.data(
      const FoodPulseFallbackRepository().orderConfirmation(orderNumber),
    );
  }
}

class _FakeFoodPulseCheckoutRiskRepository
    implements FoodPulseCheckoutRiskRepository {
  _FakeFoodPulseCheckoutRiskRepository({required this.onPredictRisk});

  final Future<RiskPredictionResponse> Function(CheckoutRiskRequest request)
  onPredictRisk;
  final List<CheckoutRiskRequest> requests = [];

  @override
  Future<RiskPredictionResponse> predictRisk(CheckoutRiskRequest request) {
    requests.add(request);
    return onPredictRisk(request);
  }
}

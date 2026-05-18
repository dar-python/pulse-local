import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/app/foodpulse_app.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';

void main() {
  testWidgets('starts on local login and rejects non-demo credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const FoodPulseApp());

    expect(find.text('FoodPulse'), findsOneWidget);
    expect(find.text('Username: user / Password: pass'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_username')), 'bad');
    await tester.enterText(find.byKey(const Key('login_password')), 'creds');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Invalid demo credentials.'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('navigates the mock FoodPulse ordering flow', (tester) async {
    await tester.pumpWidget(
      FoodPulseRepositoryScope(
        repository: const _StaticFoodPulseRepository(),
        child: FoodPulseCheckoutRiskScope(
          repository: _StaticFoodPulseCheckoutRiskRepository(
            const RiskPredictionResponse(
              success: true,
              source: 'ml-service',
              riskScore: 0.68,
              riskLevel: 'Medium',
              recommendation: 'Medium fulfillment risk. Keep ETA visible.',
            ),
          ),
          child: const FoodPulseApp(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login_username')), 'user');
    await tester.enterText(find.byKey(const Key('login_password')), 'pass');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Tacloban City, E. Visayas'), findsOneWidget);
    expect(find.text('Tambayan Grill'), findsOneWidget);

    await tester.tap(find.text('Tambayan Grill').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Low fulfillment risk (28%) · ETA on track'),
      findsOneWidget,
    );
    expect(find.text('Pork Sinigang'), findsOneWidget);

    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('₱554'), findsWidgets);

    await tester.tap(find.text('Proceed to Checkout →'));
    await tester.pumpAndSettle();

    expect(find.text('Fulfillment Risk Score'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('MEDIUM RISK'), findsWidgets);
    expect(find.text('GCash'), findsOneWidget);

    await tester.ensureVisible(find.text('Place Order · ₱554'));
    await tester.tap(find.text('Place Order · ₱554'));
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(find.text('Order #FP-2024-9873'), findsOneWidget);
    expect(find.text('68% · adjusting ETA'), findsOneWidget);
  });
}

class _StaticFoodPulseCheckoutRiskRepository
    implements FoodPulseCheckoutRiskRepository {
  const _StaticFoodPulseCheckoutRiskRepository(this.response);

  final RiskPredictionResponse response;

  @override
  Future<RiskPredictionResponse> predictRisk(
    CheckoutRiskRequest request,
  ) async {
    return response;
  }
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

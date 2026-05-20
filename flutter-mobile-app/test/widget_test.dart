import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/app/foodpulse_app.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/core/network/api_exception.dart';
import 'package:pulse_local_app/features/auth/auth_api_service.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('starts on local login and rejects non-demo credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      FoodPulseApp(
        authApiService: _StaticAuthApiService(
          error: const ApiException('Invalid demo credentials.'),
        ),
      ),
    );

    expect(find.text('Log in to your account'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_username')), 'bad');
    await tester.enterText(find.byKey(const Key('login_password')), 'creds');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
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
          child: FoodPulseApp(authApiService: _StaticAuthApiService()),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login_username')), 'user');
    await tester.enterText(find.byKey(const Key('login_password')), 'pass');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Tacloban City, E. Visayas'), findsOneWidget);
    expect(find.text("McDonald's Tacloban"), findsOneWidget);

    await tester.ensureVisible(find.text("McDonald's Tacloban").first);
    await tester.tap(find.text("McDonald's Tacloban").first);
    await tester.pumpAndSettle();

    expect(
      find.text('Low fulfillment risk (28%) / ETA on track'),
      findsOneWidget,
    );
    expect(find.text('Pork Sinigang'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.textContaining('234'), findsWidgets);

    await tester.tap(find.textContaining('Place order'));
    await tester.pumpAndSettle();

    expect(find.text('Fulfillment Risk Score'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('MEDIUM RISK'), findsWidgets);
    expect(find.text('GCash'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order Confirmed!'), findsOneWidget);
    expect(find.text('Order #FP-2024-9873'), findsOneWidget);
    expect(find.text('68% - adjusting ETA'), findsOneWidget);
  });
}

class _StaticAuthApiService extends AuthApiService {
  _StaticAuthApiService({this.error});

  final ApiException? error;

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }

    return AuthUser(
      username: username,
      name: username,
      email: '$username@foodpulse.local',
      contactNumber: '09175550148',
    );
  }
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

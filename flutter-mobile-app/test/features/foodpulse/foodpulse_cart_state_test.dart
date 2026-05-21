import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/menu_item.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';
import 'package:pulse_local_app/features/cart/cart_screen.dart';
import 'package:pulse_local_app/features/cart/foodpulse_cart_controller.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/foodpulse/models/foodpulse_order.dart';
import 'package:pulse_local_app/features/foodpulse/repositories/foodpulse_repository.dart';
import 'package:pulse_local_app/features/home/home_screen.dart';
import 'package:pulse_local_app/features/restaurant/restaurant_screen.dart';
import 'package:pulse_local_app/shared/widgets/primary_button.dart';

void main() {
  testWidgets('adding a menu item starts from an empty cart', (tester) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          menuByRestaurantId: {
            1: RestaurantMenu(
              restaurant: MockFoodPulseData.restaurants.first,
              items: const [_porkSinigang],
            ),
          },
        ),
        child: RestaurantScreen(
          restaurant: MockFoodPulseData.restaurants.first,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Cart'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text("McDonald's Tacloban"), findsOneWidget);
    expect(find.text('Pork Sinigang'), findsOneWidget);
    expect(find.textContaining('370'), findsNothing);
  });

  testWidgets('home cart badge follows the actual cart quantity', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(
          menuByRestaurantId: {
            1: RestaurantMenu(
              restaurant: MockFoodPulseData.restaurants.first,
              items: const [_porkSinigang],
            ),
          },
        ),
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_cart_badge_count')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('home_cart_badge_count'))).data,
      '0',
    );

    await tester.ensureVisible(find.text("McDonald's Tacloban").first);
    await tester.tap(find.text("McDonald's Tacloban").first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('home_cart_badge_count'))).data,
      '1',
    );
  });

  testWidgets('cart and checkout use the selected restaurant and item', (
    tester,
  ) async {
    final restaurant = MockFoodPulseData.restaurants[1];
    final repository = _FakeFoodPulseRepository(
      menuByRestaurantId: {
        2: RestaurantMenu(restaurant: restaurant, items: const [_chickenjoy]),
      },
      checkoutHandler: (request) async =>
          FoodPulseResult.data(_checkoutFromRequest('FP-JOLLIBEE-1', request)),
      confirmationHandler: (orderNumber) async => FoodPulseResult.data(
        _confirmation(orderNumber, restaurant: restaurant),
      ),
    );

    await tester.pumpWidget(
      _wrapped(
        repository: repository,
        child: RestaurantScreen(restaurant: restaurant),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Jollibee Tacloban'), findsOneWidget);
    expect(find.text('Chickenjoy Meal'), findsOneWidget);
    expect(find.textContaining('149'), findsWidgets);
    expect(find.textContaining('188'), findsWidgets);

    await tester.tap(find.byKey(const Key('cart_checkout_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Place Order'));
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    expect(
      repository.checkoutRequests.single.restaurant.name,
      'Jollibee Tacloban',
    );
    expect(repository.checkoutRequests.single.items, hasLength(1));
    expect(
      repository.checkoutRequests.single.items.single.item.name,
      'Chickenjoy Meal',
    );
    expect(repository.checkoutRequests.single.items.single.quantity, 1);
  });

  testWidgets('cart controls increase and decrease item quantity', (
    tester,
  ) async {
    final controller = FoodPulseCartController()
      ..addItem(
        restaurant: MockFoodPulseData.restaurants.first,
        item: _porkSinigang,
      );

    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(),
        child: CartScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          cartController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cart_item_increase_1')));
    await tester.pumpAndSettle();

    expect(controller.totalQuantity, 2);
    expect(find.textContaining('370'), findsWidgets);

    await tester.tap(find.byKey(const Key('cart_item_decrease_1')));
    await tester.pumpAndSettle();

    expect(controller.totalQuantity, 1);
    expect(find.textContaining('370'), findsNothing);

    await tester.tap(find.byKey(const Key('cart_item_decrease_1')));
    await tester.pumpAndSettle();

    expect(controller.isEmpty, isTrue);
    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('cart controls remove an individual item', (tester) async {
    final controller = FoodPulseCartController()
      ..addItem(
        restaurant: MockFoodPulseData.restaurants.first,
        item: _porkSinigang,
      );

    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(),
        child: CartScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          cartController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cart_item_remove_1')));
    await tester.pumpAndSettle();

    expect(controller.isEmpty, isTrue);
    expect(find.text('Pork Sinigang'), findsNothing);
    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('clear cart asks for confirmation before removing all items', (
    tester,
  ) async {
    final controller = FoodPulseCartController()
      ..addItem(
        restaurant: MockFoodPulseData.restaurants.first,
        item: _porkSinigang,
      )
      ..addItem(
        restaurant: MockFoodPulseData.restaurants.first,
        item: _chickenjoy,
      );

    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(),
        child: CartScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          cartController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cart_clear_all')));
    await tester.pumpAndSettle();

    expect(find.text('Clear all items from your cart?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(controller.totalQuantity, 2);

    await tester.tap(find.byKey(const Key('cart_clear_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Cart'));
    await tester.pumpAndSettle();

    expect(controller.isEmpty, isTrue);
    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('checkout button is disabled when cart is empty', (tester) async {
    await tester.pumpWidget(
      _wrapped(
        repository: _FakeFoodPulseRepository(),
        child: CartScreen(
          restaurant: MockFoodPulseData.restaurants.first,
          cartController: FoodPulseCartController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkoutButton = tester.widget<PrimaryButton>(
      find.byKey(const Key('cart_checkout_button')),
    );

    expect(checkoutButton.onPressed, isNull);
  });

  testWidgets('adding from another restaurant prompts before clearing cart', (
    tester,
  ) async {
    final repository = _FakeFoodPulseRepository(
      menuByRestaurantId: {
        1: RestaurantMenu(
          restaurant: MockFoodPulseData.restaurants[0],
          items: const [_porkSinigang],
        ),
        2: RestaurantMenu(
          restaurant: MockFoodPulseData.restaurants[1],
          items: const [_chickenjoy],
        ),
      },
    );

    await tester.pumpWidget(
      _wrapped(repository: repository, child: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("McDonald's Tacloban").first);
    await tester.tap(find.text("McDonald's Tacloban").first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Jollibee Tacloban').first);
    await tester.tap(find.text('Jollibee Tacloban').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Starting a new order will clear your current cart.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Cart and Add Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Jollibee Tacloban'), findsOneWidget);
    expect(find.text('Chickenjoy Meal'), findsOneWidget);
    expect(find.text('Pork Sinigang'), findsNothing);
  });
}

const _porkSinigang = MenuItem(
  id: 1,
  name: 'Pork Sinigang',
  description: 'Sour tamarind broth',
  price: 185,
  emoji: 'PS',
  category: 'Bestsellers',
);

const _chickenjoy = MenuItem(
  id: 6,
  name: 'Chickenjoy Meal',
  description: 'Crispy fried chicken with rice and gravy',
  price: 149,
  emoji: 'CJ',
  category: 'Bestsellers',
);

Widget _wrapped({
  required FoodPulseRepository repository,
  FoodPulseCheckoutRiskRepository riskRepository =
      const _StaticRiskRepository(),
  required Widget child,
}) {
  return FoodPulseRepositoryScope(
    repository: repository,
    child: FoodPulseCheckoutRiskScope(
      repository: riskRepository,
      child: MaterialApp(home: child),
    ),
  );
}

CheckoutSummary _checkoutFromRequest(
  String orderNumber,
  CheckoutCartRequest request,
) {
  final items = request.items
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
  final subtotal = request.items.fold<int>(
    0,
    (sum, cartItem) => sum + cartItem.lineTotal,
  );

  return CheckoutSummary(
    orderNumber: orderNumber,
    status: 'ready_for_confirmation',
    restaurant: request.restaurant,
    items: items,
    paymentMethod: request.paymentMethod,
    subtotal: subtotal,
    deliveryFee: MockFoodPulseData.deliveryFee,
    serviceCharge: MockFoodPulseData.serviceCharge,
    total:
        subtotal +
        MockFoodPulseData.deliveryFee +
        MockFoodPulseData.serviceCharge,
    risk: const FoodPulseOrderRisk(
      score: 68,
      level: 'Medium',
      recommendation: 'Medium fulfillment risk. Keep ETA visible.',
    ),
  );
}

OrderConfirmation _confirmation(String orderNumber, {Restaurant? restaurant}) {
  return OrderConfirmation(
    orderNumber: orderNumber,
    status: 'confirmed',
    estimatedArrival: '25-35 min',
    restaurant: restaurant ?? MockFoodPulseData.restaurants.first,
    items: const [],
    paymentMethod: 'cod',
    subtotal: 149,
    deliveryFee: 49,
    serviceCharge: 10,
    total: 208,
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
    Map<int, RestaurantMenu>? menuByRestaurantId,
    this.checkoutHandler,
    this.confirmationHandler,
  }) : menuByRestaurantId = menuByRestaurantId ?? const {};

  final Map<int, RestaurantMenu> menuByRestaurantId;
  final Future<FoodPulseResult<CheckoutSummary>> Function(
    CheckoutCartRequest request,
  )?
  checkoutHandler;
  final Future<FoodPulseResult<OrderConfirmation>> Function(String orderNumber)?
  confirmationHandler;
  final List<CheckoutCartRequest> checkoutRequests = [];

  @override
  Future<FoodPulseResult<List<Restaurant>>> fetchRestaurants() async {
    return FoodPulseResult.data(MockFoodPulseData.restaurants);
  }

  @override
  Future<FoodPulseResult<RestaurantMenu>> fetchMenu(int restaurantId) async {
    return FoodPulseResult.data(
      menuByRestaurantId[restaurantId] ??
          RestaurantMenu(
            restaurant: MockFoodPulseData.restaurants.first,
            items: const [_porkSinigang],
          ),
    );
  }

  @override
  Future<FoodPulseResult<CheckoutSummary>> checkoutCart(
    CheckoutCartRequest request,
  ) {
    checkoutRequests.add(request);
    return checkoutHandler?.call(request) ??
        Future.value(
          FoodPulseResult.data(_checkoutFromRequest('FP-TEST-1', request)),
        );
  }

  @override
  Future<FoodPulseResult<OrderConfirmation>> fetchOrderConfirmation(
    String orderNumber,
  ) {
    return confirmationHandler?.call(orderNumber) ??
        Future.value(FoodPulseResult.data(_confirmation(orderNumber)));
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

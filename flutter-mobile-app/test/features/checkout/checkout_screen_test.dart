import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/network/api_exception.dart';
import 'package:pulse_local_app/features/checkout/checkout_screen.dart';
import 'package:pulse_local_app/features/checkout/repositories/foodpulse_checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';

void main() {
  testWidgets('loads the Laravel prediction and displays medium risk', (
    tester,
  ) async {
    final completer = Completer<RiskPredictionResponse>();
    final repository = _FakeFoodPulseCheckoutRiskRepository(
      onPredictRisk: (_) => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(home: CheckoutScreen(checkoutRiskRepository: repository)),
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
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requests.single.toJson(), {
      'rider_to_order_ratio': 0.45,
      'merchant_prep_time': 25,
      'traffic_corridor_intensity': 'high',
      'weather_category': 'rainy',
      'delivery_distance_km': 4.2,
      'address_complexity': 'medium',
      'payment_method': 'cod',
    });
    expect(find.text('68%'), findsOneWidget);
    expect(find.text('MEDIUM RISK'), findsWidgets);
    expect(
      find.text('Medium fulfillment risk. Keep ETA visible.'),
      findsOneWidget,
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: CheckoutScreen(checkoutRiskRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('72%'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsWidgets);
    expect(
      find.text('High fulfillment risk. Adjust ETA and notify merchant.'),
      findsOneWidget,
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: CheckoutScreen(checkoutRiskRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('UNKNOWN RISK'), findsWidgets);
    expect(
      find.text('Fallback risk mode active. You can still place your order.'),
      findsOneWidget,
    );
    expect(find.textContaining('laravel-fallback'), findsOneWidget);
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
      MaterialApp(home: CheckoutScreen(checkoutRiskRepository: repository)),
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

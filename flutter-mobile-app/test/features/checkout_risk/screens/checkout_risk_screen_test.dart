import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/network/api_exception.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/models/risk_prediction_response.dart';
import 'package:pulse_local_app/features/checkout_risk/screens/checkout_risk_screen.dart';
import 'package:pulse_local_app/features/checkout_risk/services/checkout_risk_api_service.dart';

void main() {
  testWidgets('submits the form and displays the prediction result', (
    tester,
  ) async {
    final completer = Completer<RiskPredictionResponse>();
    final service = _FakeCheckoutRiskApiService(
      onPredictRisk: (_) => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(home: CheckoutRiskScreen(apiService: service)),
    );

    await _tapSubmitButton(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const RiskPredictionResponse(
        success: true,
        source: 'ml-service',
        riskScore: 0.71,
        riskLevel: 'High',
        recommendation:
            'High fulfillment risk. Adjust ETA and notify merchant.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Risk Score: 71%'), findsOneWidget);
    expect(find.text('Risk Level: High'), findsOneWidget);
    expect(
      find.text('High fulfillment risk. Adjust ETA and notify merchant.'),
      findsOneWidget,
    );
    expect(find.text('Source: ml-service'), findsOneWidget);
  });

  testWidgets('shows an error state when Laravel cannot be reached', (
    tester,
  ) async {
    final service = _FakeCheckoutRiskApiService(
      onPredictRisk: (_) async {
        throw const ApiException('Laravel checkout risk API cannot be reached.');
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: CheckoutRiskScreen(apiService: service)),
    );

    await _tapSubmitButton(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Unable to calculate fulfillment risk.'),
      findsOneWidget,
    );
    expect(find.textContaining('Laravel checkout risk API'), findsOneWidget);
  });
}

Future<void> _tapSubmitButton(WidgetTester tester) async {
  final buttonText = find.text('Calculate Fulfillment Risk');

  await tester.scrollUntilVisible(
    buttonText,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(buttonText);
  await tester.pump();
}

class _FakeCheckoutRiskApiService extends CheckoutRiskApiService {
  _FakeCheckoutRiskApiService({required this.onPredictRisk})
    : super(dio: Dio());

  final Future<RiskPredictionResponse> Function(CheckoutRiskRequest request)
  onPredictRisk;

  @override
  Future<RiskPredictionResponse> predictRisk(CheckoutRiskRequest request) {
    return onPredictRisk(request);
  }
}

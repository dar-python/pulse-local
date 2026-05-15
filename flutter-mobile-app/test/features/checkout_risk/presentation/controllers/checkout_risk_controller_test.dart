import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/data/models/checkout_risk_request.dart';
import 'package:pulse_local_app/features/checkout_risk/domain/entities/checkout_risk_result.dart';
import 'package:pulse_local_app/features/checkout_risk/domain/repositories/checkout_risk_repository.dart';
import 'package:pulse_local_app/features/checkout_risk/domain/usecases/calculate_checkout_risk.dart';
import 'package:pulse_local_app/features/checkout_risk/presentation/controllers/checkout_risk_controller.dart';

void main() {
  test('starts in initial state and exposes a sprint sample request', () {
    final controller = CheckoutRiskController(
      CalculateCheckoutRisk(_SuccessfulRepository()),
    );

    expect(controller.state.status, CheckoutRiskStatus.initial);
    expect(
      CheckoutRiskController.sampleRequest.trafficCorridorIntensity,
      'high',
    );
    expect(CheckoutRiskController.sampleRequest.addressComplexity, 'medium');
    expect(CheckoutRiskController.sampleRequest.paymentMethod, 'cod');
  });

  test('sets success state when checkout risk calculation succeeds', () async {
    final controller = CheckoutRiskController(
      CalculateCheckoutRisk(_SuccessfulRepository()),
    );

    await controller.calculateRisk();

    expect(controller.state.status, CheckoutRiskStatus.success);
    expect(controller.state.result?.riskLevel, 'High');
    expect(controller.state.result?.source, 'ml-service');
  });

  test('sets error state when checkout risk calculation fails', () async {
    final controller = CheckoutRiskController(
      CalculateCheckoutRisk(_FailingRepository()),
    );

    await controller.calculateRisk();

    expect(controller.state.status, CheckoutRiskStatus.error);
    expect(controller.state.errorMessage, contains('Unable to calculate'));
  });
}

class _SuccessfulRepository implements CheckoutRiskRepository {
  @override
  Future<CheckoutRiskResult> calculateRisk(CheckoutRiskRequest request) async {
    return const CheckoutRiskResult(
      riskScore: 0.72,
      riskLevel: 'High',
      recommendation: 'High fulfillment risk. Adjust ETA and notify merchant.',
      source: 'ml-service',
    );
  }
}

class _FailingRepository implements CheckoutRiskRepository {
  @override
  Future<CheckoutRiskResult> calculateRisk(CheckoutRiskRequest request) async {
    throw Exception('network unavailable');
  }
}

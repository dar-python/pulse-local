import '../../data/models/checkout_risk_request.dart';
import '../entities/checkout_risk_result.dart';

abstract class CheckoutRiskRepository {
  Future<CheckoutRiskResult> calculateRisk(CheckoutRiskRequest request);
}

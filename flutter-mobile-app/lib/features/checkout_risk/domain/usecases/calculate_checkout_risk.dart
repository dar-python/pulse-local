import '../../data/models/checkout_risk_request.dart';
import '../entities/checkout_risk_result.dart';
import '../repositories/checkout_risk_repository.dart';

class CalculateCheckoutRisk {
  const CalculateCheckoutRisk(this._repository);

  final CheckoutRiskRepository _repository;

  Future<CheckoutRiskResult> call(CheckoutRiskRequest request) {
    return _repository.calculateRisk(request);
  }
}

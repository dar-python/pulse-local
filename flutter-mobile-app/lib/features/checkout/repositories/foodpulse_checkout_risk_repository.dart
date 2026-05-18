import 'package:flutter/widgets.dart';

import '../../checkout_risk/models/checkout_risk_request.dart';
import '../../checkout_risk/models/risk_prediction_response.dart';
import '../../checkout_risk/services/checkout_risk_api_service.dart';

abstract class FoodPulseCheckoutRiskRepository {
  Future<RiskPredictionResponse> predictRisk(CheckoutRiskRequest request);
}

class LaravelFoodPulseCheckoutRiskRepository
    implements FoodPulseCheckoutRiskRepository {
  LaravelFoodPulseCheckoutRiskRepository({CheckoutRiskApiService? apiService})
    : _apiService = apiService ?? CheckoutRiskApiService();

  final CheckoutRiskApiService _apiService;

  @override
  Future<RiskPredictionResponse> predictRisk(CheckoutRiskRequest request) {
    return _apiService.predictRisk(request);
  }
}

class FoodPulseCheckoutRiskScope extends InheritedWidget {
  const FoodPulseCheckoutRiskScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final FoodPulseCheckoutRiskRepository repository;

  static FoodPulseCheckoutRiskRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FoodPulseCheckoutRiskScope>()
        ?.repository;
  }

  @override
  bool updateShouldNotify(FoodPulseCheckoutRiskScope oldWidget) {
    return oldWidget.repository != repository;
  }
}

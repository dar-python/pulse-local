import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/checkout_risk_remote_datasource.dart';
import '../../data/models/checkout_risk_request.dart';
import '../../data/repositories/checkout_risk_repository_impl.dart';
import '../../domain/entities/checkout_risk_result.dart';
import '../../domain/repositories/checkout_risk_repository.dart';
import '../../domain/usecases/calculate_checkout_risk.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final checkoutRiskRemoteDataSourceProvider =
    Provider<CheckoutRiskRemoteDataSource>(
      (ref) => CheckoutRiskRemoteDataSource(ref.watch(dioClientProvider)),
    );

final checkoutRiskRepositoryProvider = Provider<CheckoutRiskRepository>(
  (ref) => CheckoutRiskRepositoryImpl(
    ref.watch(checkoutRiskRemoteDataSourceProvider),
  ),
);

final calculateCheckoutRiskProvider = Provider<CalculateCheckoutRisk>(
  (ref) => CalculateCheckoutRisk(ref.watch(checkoutRiskRepositoryProvider)),
);

final checkoutRiskControllerProvider =
    StateNotifierProvider<CheckoutRiskController, CheckoutRiskState>(
      (ref) => CheckoutRiskController(ref.watch(calculateCheckoutRiskProvider)),
    );

enum CheckoutRiskStatus { initial, loading, success, error }

class CheckoutRiskState {
  const CheckoutRiskState._({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const CheckoutRiskState.initial()
    : this._(status: CheckoutRiskStatus.initial);

  const CheckoutRiskState.loading()
    : this._(status: CheckoutRiskStatus.loading);

  const CheckoutRiskState.success(CheckoutRiskResult result)
    : this._(status: CheckoutRiskStatus.success, result: result);

  const CheckoutRiskState.error(String message)
    : this._(status: CheckoutRiskStatus.error, errorMessage: message);

  final CheckoutRiskStatus status;
  final CheckoutRiskResult? result;
  final String? errorMessage;

  bool get isLoading => status == CheckoutRiskStatus.loading;
}

class CheckoutRiskController extends StateNotifier<CheckoutRiskState> {
  CheckoutRiskController(this._calculateCheckoutRisk)
    : super(const CheckoutRiskState.initial());

  final CalculateCheckoutRisk _calculateCheckoutRisk;

  static const CheckoutRiskRequest sampleRequest = CheckoutRiskRequest(
    riderToOrderRatio: 0.45,
    merchantPrepTime: 25,
    trafficCorridorIntensity: 'high',
    deliveryDistanceKm: 4.2,
    addressComplexity: 'medium',
    paymentMethod: 'cod',
  );

  Future<void> calculateRisk([CheckoutRiskRequest? request]) async {
    state = const CheckoutRiskState.loading();

    try {
      final result = await _calculateCheckoutRisk(request ?? sampleRequest);
      state = CheckoutRiskState.success(result);
    } catch (error) {
      state = CheckoutRiskState.error(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(Object error) {
    if (error is ApiException) {
      return 'Unable to calculate fulfillment risk. ${error.message}';
    }

    return 'Unable to calculate fulfillment risk. Check the Laravel API and try again.';
  }
}

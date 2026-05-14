import '../../domain/entities/checkout_risk_result.dart';
import '../../domain/repositories/checkout_risk_repository.dart';
import '../datasources/checkout_risk_remote_datasource.dart';
import '../models/checkout_risk_request.dart';

class CheckoutRiskRepositoryImpl implements CheckoutRiskRepository {
  const CheckoutRiskRepositoryImpl(this._remoteDataSource);

  final CheckoutRiskRemoteDataSource _remoteDataSource;

  @override
  Future<CheckoutRiskResult> calculateRisk(CheckoutRiskRequest request) async {
    final response = await _remoteDataSource.calculateRisk(request);
    return response.toEntity();
  }
}

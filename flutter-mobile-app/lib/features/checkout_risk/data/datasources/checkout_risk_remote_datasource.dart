import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/checkout_risk_request.dart';
import '../models/checkout_risk_response.dart';

class CheckoutRiskRemoteDataSource {
  const CheckoutRiskRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<CheckoutRiskResponse> calculateRisk(
    CheckoutRiskRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.checkoutRiskEndpoint,
        data: request.toJson(),
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw ApiException(
          'The checkout risk response was not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      final parsed = CheckoutRiskResponse.fromJson(payload);
      if (!parsed.success) {
        throw ApiException(
          'The checkout risk request was not successful.',
          statusCode: response.statusCode,
        );
      }

      return parsed;
    } on DioException catch (error) {
      throw ApiException(
        _messageForDioError(error),
        statusCode: error.response?.statusCode,
      );
    } on FormatException catch (error) {
      throw ApiException(error.message);
    }
  }

  String _messageForDioError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return 'Unable to reach the Laravel checkout risk API.';
  }
}

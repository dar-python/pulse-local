import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../models/checkout_risk_request.dart';
import '../models/risk_prediction_response.dart';

class CheckoutRiskApiService {
  CheckoutRiskApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.laravelBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  Future<RiskPredictionResponse> predictRisk(
    CheckoutRiskRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.checkoutRiskEndpoint,
        data: request.toJson(),
      );
      final data = response.data;

      if (data == null) {
        throw ApiException(
          'Laravel returned an empty checkout risk response.',
          statusCode: response.statusCode,
        );
      }

      final prediction = RiskPredictionResponse.fromJson(data);
      if (!prediction.success) {
        throw ApiException(
          'Laravel could not calculate fulfillment risk.',
          statusCode: response.statusCode,
        );
      }

      return prediction;
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

    return 'Laravel checkout risk API cannot be reached.';
  }
}

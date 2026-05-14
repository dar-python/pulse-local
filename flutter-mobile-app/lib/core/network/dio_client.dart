import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.laravelBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.json,
            ),
          );

  final Dio dio;

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return dio.post(path, data: data);
  }
}

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';

class AuthApiService {
  AuthApiService({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  final DioClient _dioClient;


  Future<AuthUser> register({
    required String username,
    required String email,
    required String contactNumber,
    required String password,
  }) async {
    final payload = await _post(
      ApiConstants.authRegisterEndpoint,
      data: {
        'username': username,
        'email': email,
        'contact_number': contactNumber,
        'password': password,
      },
    );

    return AuthUser.fromJson(_userPayload(payload));
  }

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final payload = await _post(
      ApiConstants.authLoginEndpoint,
      data: {
        'username': username,
        'password': password,
      },
    );

    return AuthUser.fromJson(_userPayload(payload));
  }

  Future<AuthUser> updateProfile({
    required String username,
    required String password,
    required String email,
    required String contactNumber,
  }) async {
    final payload = await _put(
      ApiConstants.authProfileEndpoint,
      data: {
        'username': username,
        'password': password,
        'email': email,
        'contact_number': contactNumber,
      },
    );

    return AuthUser.fromJson(_userPayload(payload));
  }

  Future<AuthUser> updatePassword({
    required String username,
    required String currentPassword,
    required String password,
  }) async {
    final payload = await _put(
      ApiConstants.authPasswordEndpoint,
      data: {
        'username': username,
        'current_password': currentPassword,
        'password': password,
      },
    );

    return AuthUser.fromJson(_userPayload(payload));
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Object data,
  }) async {
    try {
      final response = await _dioClient.post(path, data: data);
      final payload = response.data;
      if (payload is! Map<String, dynamic> || payload['success'] != true) {
        throw ApiException(
          'The authentication response was invalid.',
          statusCode: response.statusCode,
        );
      }

      return payload;
    } on DioException catch (error) {
      throw ApiException(
        _messageForDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    required Object data,
  }) async {
    try {
      final response = await _dioClient.put(path, data: data);
      final payload = response.data;
      if (payload is! Map<String, dynamic> || payload['success'] != true) {
        throw ApiException(
          'The authentication response was invalid.',
          statusCode: response.statusCode,
        );
      }

      return payload;
    } on DioException catch (error) {
      throw ApiException(
        _messageForDioError(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _userPayload(Map<String, dynamic> payload) {
    final user = payload['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiException('The authentication user response was invalid.');
    }

    return user;
  }

  String _messageForDioError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final errors = responseData['errors'];
      if (errors is Map<String, dynamic>) {
        for (final entry in errors.values) {
          if (entry is List && entry.isNotEmpty && entry.first is String) {
            return entry.first as String;
          }
        }
      }
    }

    return 'Unable to reach the Laravel account API.';
  }
}

class AuthUser {
  const AuthUser({
    required this.username,
    required this.name,
    required this.email,
    required this.contactNumber,
  });

  final String username;
  final String name;
  final String email;
  final String contactNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
    );
  }
}

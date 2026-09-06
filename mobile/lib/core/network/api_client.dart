import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient(this._storage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    ]);
  }

  final Dio _dio;
  final SecureStorage _storage;

  Dio get dio => _dio;
}

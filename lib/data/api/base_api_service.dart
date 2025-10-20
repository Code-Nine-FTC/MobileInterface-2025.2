import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import '../../core/utils/secure_storage_service.dart';

class BaseApiService {
  Dio get dio => _dio;
  // Método para PATCH
  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await _dio.patch(path, data: data, options: options);
  }
  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  BaseApiService() {
    final baseUrl = _resolveBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Interceptor para adicionar token automaticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token'; // Adiciona token no header
            print('[BaseApiService] Header Authorization adicionado');
          } else {
            print('[BaseApiService] ATENÇÃO: Token não encontrado!');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Trate erros globais (ex: 401 para logout)
          if (error.response?.statusCode == 401) {
            // Logout automático se token inválido
            print('Token inválido, faça logout');
          }
          handler.next(error);
        },
      ),
    );

    // Interceptor de LOG em modo debug (redige Authorization)
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            try {
              final headers = Map<String, dynamic>.from(options.headers);
              if (headers.containsKey('Authorization')) {
                headers['Authorization'] = 'Bearer ***';
              }
              print('[HTTP] => ${options.method} ${options.uri}');
              if (headers.isNotEmpty) print('[HTTP] Headers: $headers');
              if (options.queryParameters.isNotEmpty) {
                print('[HTTP] Query: ${options.queryParameters}');
              }
              if (options.data != null) {
                print('[HTTP] Body: ${options.data}');
              }
            } catch (_) {}
            handler.next(options);
          },
          onResponse: (response, handler) {
            try {
              print('[HTTP] <= ${response.statusCode} ${response.requestOptions.uri}');
              print('[HTTP] Response: ${response.data}');
            } catch (_) {}
            handler.next(response);
          },
          onError: (error, handler) {
            try {
              print('[HTTP][ERR] ${error.response?.statusCode} ${error.requestOptions.uri}');
              print('[HTTP][ERR] Data: ${error.response?.data}');
              print('[HTTP][ERR] Message: ${error.message}');
            } catch (_) {}
            handler.next(error);
          },
        ),
      );
    }
  }

  String _resolveBaseUrl() {
    const port = 8080;
    if (kIsWeb) return 'http://localhost:$port';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // AVD usa 10.0.2.2; Genymotion pode usar 10.0.3.2 (poderemos tornar configurável depois)
        return 'http://10.0.2.2:$port';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:$port';
    }
  }

  // Método para GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // Método para POST
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  // Adicione PUT, DELETE, etc., conforme necessário
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
import 'package:dio/dio.dart';
import '../../core/utils/secure_storage_service.dart';

class BaseApiService {
  // Método para PATCH
  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await _dio.patch(path, data: data, options: options);
  }
  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  BaseApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8080', // Substitua pela URL base real
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
import 'base_api_service.dart';
import 'package:dio/dio.dart';

class UserApiData {
  final BaseApiService _apiService = BaseApiService();

  Future<bool> updatePassword(int userId, String password, String name) async {
    try{
       final response = await _apiService.put('/users/${userId}', data: {"password": password, "name": name} );
       if (response.statusCode == 200) return true;
       return false;
    }on DioException catch (e){
      print(e);
      throw Exception('Falha ao excluir fornecedor: $e');
    }
  }


}
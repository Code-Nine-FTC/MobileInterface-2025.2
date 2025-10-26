import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../../domain/entities/lot.dart';

class LotApiDataSource extends BaseApiService {
  Future<Lot> createLot({
    required int itemId,
    required String code,
    String? expireDate, // yyyy-MM-dd
    required int quantity,
  }) async {
    final Response response = await post(
      '/api/lotes',
      data: {
        'itemId': itemId,
        'code': code,
        if (expireDate != null && expireDate.isNotEmpty) 'expireDate': expireDate,
        'quantity': quantity,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) return Lot.fromJson(data);
      throw Exception('Resposta inesperada ao criar lote: ${response.data}');
    }
    throw Exception('Erro ao criar lote: ${response.data}');
  }

  Future<List<Lot>> listLots({required int itemId}) async {
    final Response response = await get('/api/lotes', queryParameters: {'itemId': itemId});
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map<Lot>((e) => Lot.fromJson(e)).toList();
      }
      throw Exception('Formato inesperado na listagem de lotes: ${response.data}');
    }
    throw Exception('Erro ao listar lotes: ${response.data}');
  }

  Future<Lot> adjustLot({required int lotId, required int delta}) async {
    final Response response = await patch('/api/lotes/$lotId/adjust', data: {'delta': delta});
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) return Lot.fromJson(data);
      throw Exception('Formato inesperado ao ajustar lote: ${response.data}');
    }
    throw Exception('Erro ao ajustar lote: ${response.data}');
  }
}

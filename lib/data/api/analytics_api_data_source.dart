import 'package:dio/dio.dart';
import 'base_api_service.dart';

class AnalyticsApiDataSource {
  final BaseApiService _api = BaseApiService();

  Future<List<dynamic>> getTopMaterials({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
    bool onlyCompleted = false,
  }) async {
    final Response res = await _api.get(
      '/api/analytics/materiais/top',
      queryParameters: {
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'limit': limit,
        'onlyCompleted': onlyCompleted.toString(),
      },
    );
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) return List<dynamic>.from(data);
    }
    throw Exception('Falha ao buscar Top materiais: ${res.data}');
  }

  Future<List<dynamic>> getGroupDemand({
    required DateTime startDate,
    required DateTime endDate,
    bool onlyCompleted = false,
  }) async {
    final Response res = await _api.get(
      '/api/analytics/grupos/demanda',
      queryParameters: {
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'onlyCompleted': onlyCompleted.toString(),
      },
    );
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) return List<dynamic>.from(data);
    }
    throw Exception('Falha ao buscar demanda por grupo: ${res.data}');
  }

  Future<Map<String, dynamic>> getGroupDemandSeries({
    required DateTime startDate,
    required DateTime endDate,
    String step = 'month',
    bool onlyCompleted = false,
  }) async {
    final Response res = await _api.get(
      '/api/analytics/grupos/demanda-series',
      queryParameters: {
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'step': step,
        'onlyCompleted': onlyCompleted.toString(),
      },
    );
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    throw Exception('Falha ao buscar série de demanda por grupo: ${res.data}');
  }

  Future<List<dynamic>> getSectionConsumption({
    required DateTime startDate,
    required DateTime endDate,
    bool onlyCompleted = false,
    bool onlyConsumers = true,
    bool onlyActiveConsumers = true,
  }) async {
    final Response res = await _api.get(
      '/api/analytics/secoes/consumo',
      queryParameters: {
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'onlyCompleted': onlyCompleted.toString(),
        'onlyConsumers': onlyConsumers.toString(),
        'onlyActiveConsumers': onlyActiveConsumers.toString(),
      },
    );
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) return List<dynamic>.from(data);
    }
    throw Exception('Falha ao buscar consumo por seção: ${res.data}');
  }

  Future<Map<String, dynamic>> getSectionDemandSeries({
    required DateTime startDate,
    required DateTime endDate,
    String step = 'month',
    bool onlyCompleted = false,
    bool onlyConsumers = true,
    bool onlyActiveConsumers = true,
  }) async {
    final Response res = await _api.get(
      '/api/analytics/secoes/series',
      queryParameters: {
        'startDate': _fmt(startDate),
        'endDate': _fmt(endDate),
        'step': step,
        'onlyCompleted': onlyCompleted.toString(),
        'onlyConsumers': onlyConsumers.toString(),
        'onlyActiveConsumers': onlyActiveConsumers.toString(),
      },
    );
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data);
    }
    throw Exception('Falha ao buscar série por seção: ${res.data}');
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final d2 = d.day.toString().padLeft(2, '0');
    return '$y-$m-$d2';
  }
}

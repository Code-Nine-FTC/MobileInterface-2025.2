import 'base_api_service.dart';
import 'package:dio/dio.dart';

class SectionApiDataSource extends BaseApiService {
  Future<List<Map<String, dynamic>>> getConsumerSections() async {
    // Try /sections/consumers (if backend provides it), else fallback to /sections
    try {
      final response = await get('/sections/consumers');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) => _mapSection(e)).toList();
        }
      }
    } on DioException catch (e) {
      // Fallback on 404/403/etc.
      if ((e.response?.statusCode ?? 0) >= 400) {
        // ignore and fallback
      } else {
        rethrow;
      }
    } catch (_) {
      // ignore and fallback
    }

    try {
      final response = await get('/sections');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) => _mapSection(e)).toList();
        }
      }
    } catch (_) {}

    return [];
  }

  Map<String, dynamic> _mapSection(dynamic e) {
    final map = e is Map ? Map<String, dynamic>.from(e) : {'id': e};
    final rawId = map['id'] ?? map['sectionId'] ?? map['secaoId'];
    final title = map['title'] ?? map['name'] ?? map['descricao'] ?? map['sigla'] ?? 'Seção';
    int? id;
    if (rawId is int) id = rawId; else if (rawId is String) id = int.tryParse(rawId);
    return {
      'id': id,
      'title': title.toString(),
    };
  }
}

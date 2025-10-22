import 'base_api_service.dart';

class SectionApiDataSource extends BaseApiService {
  Future<List<Map<String, dynamic>>> getConsumerSections() async {
    final response = await get('/sections/consumers');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) {
          final id = e['id'] ?? e['sectionId'];
          final title = e['title'] ?? e['name'] ?? e['descricao'];
          return {
            'id': id is int ? id : int.tryParse(id?.toString() ?? ''),
            'title': title?.toString() ?? 'Seção',
          };
        }).toList();
      }
    }
    return [];
  }
}

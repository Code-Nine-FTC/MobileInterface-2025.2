import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart';
import '../../../data/api/analytics_api_data_source.dart';
import '../../../data/api/section_api_data_source.dart';
import '../../components/section_monthly_chart.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final _api = AnalyticsApiDataSource();
  final _sectionApi = SectionApiDataSource();

  int _navIndex = 0;
  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();
  int _monthsRange = 6; // período simplificado: últimos N meses

  // Common filters
  // Mantemos defaults usados pelo backend, mas escondemos da UI
  final bool _onlyCompleted = false;
  final bool _onlyConsumers = true;
  final bool _onlyActiveConsumers = true;
  final String _step = 'month';

  // Data
  Map<String, dynamic>? _sectionSeries;

  // Sections (for filtering charts by sections)
  List<Map<String, dynamic>> _consumerSections = [];
  final Set<int> _selectedSectionIds = <int>{};

  bool _loading = false;
  String? _error;

  void _recomputeDates() {
    // Ajusta _start/_end com base no range de meses
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    final startMonth = DateTime(now.year, now.month - (_monthsRange - 1));
    _start = DateTime(startMonth.year, startMonth.month, 1);
  }

  Future<void> _loadSectionSeries() async {
    setState(() { _loading = true; _error = null; });
    try {
      _recomputeDates();
      final series = await _api.getSectionDemandSeries(
        startDate: _start,
        endDate: _end,
        step: _step,
        onlyCompleted: _onlyCompleted,
        onlyConsumers: _onlyConsumers,
        onlyActiveConsumers: _onlyActiveConsumers,
      );
      setState(() {
        _sectionSeries = series;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConsumerSections();
  }

  Future<void> _loadConsumerSections() async {
    try {
      final sections = await _sectionApi.getConsumerSections();
      if (!mounted) return;
      setState(() {
        _consumerSections = sections;
        // keep previous selections if still valid
        _selectedSectionIds.removeWhere((id) => !_consumerSections.any((s) => (s['id'] as int?) == id));
      });
    } catch (_) {/* ignore for now */}
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Consumo mensal por seção',
      showBackButton: true,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filtersCard(),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            if (!_loading) ...[
              _section('Série mensal por seção', _buildSectionChart()),
            ]
          ],
        ),
      ),
    );
  }

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdownTile(
                  'Período',
                  'Últimos ${_monthsRange} meses',
                  const ['Últimos 3 meses', 'Últimos 6 meses', 'Últimos 12 meses'],
                  (val) {
                    if (val == null) return;
                    setState(() {
                      if (val.contains('3')) _monthsRange = 3;
                      else if (val.contains('6')) _monthsRange = 6;
                      else _monthsRange = 12;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _sectionsFilterTile(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.infoLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSectionSeries,
                    label: const Text('Atualizar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Sections filter UI and helpers ----
  Widget _sectionsFilterTile() {
    if (_consumerSections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.group, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text('Seções: carregando ou indisponível', style: TextStyle(color: Colors.grey[700]))),
            IconButton(
              tooltip: 'Recarregar seções',
              onPressed: _loadConsumerSections,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.segment, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filtrar gráficos por Seções',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
              ),
              TextButton(
                onPressed: _selectedSectionIds.isEmpty
                    ? null
                    : () => setState(() => _selectedSectionIds.clear()),
                child: const Text('Limpar'),
              ),
              TextButton(
                onPressed: _selectedSectionIds.length == _consumerSections.length
                    ? null
                    : () => setState(() => _selectedSectionIds
                        ..clear()
                        ..addAll(_consumerSections.map((s) => (s['id'] as int?) ?? -1).where((e) => e != -1))),
                child: const Text('Todos'),
              )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _consumerSections.map((s) {
              final id = (s['id'] as int?) ?? -1;
              final title = s['title']?.toString() ?? 'Seção';
              final selected = _selectedSectionIds.contains(id);
              return FilterChip(
                label: Text(title, overflow: TextOverflow.ellipsis),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (id == -1) return;
                  if (v) {
                    _selectedSectionIds.add(id);
                  } else {
                    _selectedSectionIds.remove(id);
                  }
                }),
              );
            }).toList(),
          ),
          if (_selectedSectionIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Aplicando filtro em: ${_selectedSectionIds.length} seção(ões)',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }

  // Removidos tiles antigos (data e switches) para simplificar a UI

  Widget _dropdownTile(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 0,
            child: Text('$label: ', overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                items: options
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removido controle de número (limite) para simplificação

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.infoLight.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.analytics, color: AppColors.infoLight, size: 18),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          ],
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  // Removidos métodos de lista não utilizados

  // Removido JSON card não utilizado na versão simplificada

  // Removido card de key-value não utilizado

  // ---- Filtering logic for Sections charts ----
  // Removida filtragem da lista de consumo (não usada na UI simplificada)

  Map<String, dynamic>? _filteredSectionSeries() {
    final data = _sectionSeries;
    if (data == null) return null;
    if (_selectedSectionIds.isEmpty) return data;

    final selectedIds = _selectedSectionIds;
    final selectedTitles = _consumerSections
        .where((s) => selectedIds.contains((s['id'] as int?) ?? -1))
        .map((s) => s['title']?.toString())
        .whereType<String>()
        .toSet();

    final Map<String, dynamic> out = {};
    data.forEach((key, value) {
      // try match by key (title or id as string)
      final keyIsSelectedByTitle = selectedTitles.contains(key);
      final keyAsInt = int.tryParse(key);
      final keyIsSelectedById = keyAsInt != null && selectedIds.contains(keyAsInt);
      if (keyIsSelectedByTitle || keyIsSelectedById) {
        out[key] = value;
        return;
      }

      // if value is a list of points with sectionId, try filter list
      if (value is List) {
        final filteredList = value.where((p) {
          if (p is Map) {
            final m = Map<String, dynamic>.from(p);
            final idRaw = m['sectionId'] ?? m['id'] ?? m['secaoId'];
            int? id;
            if (idRaw is int) id = idRaw;
            if (idRaw is String) id = int.tryParse(idRaw);
            if (id != null && selectedIds.contains(id)) return true;
            final title = m['title']?.toString() ?? m['name']?.toString() ?? m['descricao']?.toString();
            if (title != null && selectedTitles.contains(title)) return true;
            return false;
          }
          return true;
        }).toList();
        out[key] = filteredList;
        return;
      }
    });
    return out;
  }

  // ---- Chart helpers ----
  List<DateTime> _monthBuckets() {
    final now = DateTime.now();
    final List<DateTime> out = [];
    for (int i = _monthsRange - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      out.add(d);
    }
    return out;
  }

  Map<String, List<double>> _normalizeSeriesToBuckets(Map<String, dynamic>? raw, List<DateTime> months) {
    // Output: label -> values aligned to months
    final Map<String, List<double>> result = {};
    if (raw == null) return result;

    // Case 1: Highcharts-like shape { categories: [], series: [{name, data: []}, ...] }
    if (raw.containsKey('categories') && raw.containsKey('series')) {
      final seriesList = raw['series'];
      if (seriesList is List) {
        for (final s in seriesList) {
          if (s is Map) {
            final name = (s['name'] ?? 'Série').toString();
            final data = s['data'];
            final values = List<double>.filled(months.length, 0);
            if (data is List) {
              for (int i = 0; i < months.length; i++) {
                if (i < data.length) {
                  final num? n = data[i] is num ? data[i] as num : num.tryParse('${data[i]}');
                  values[i] = (n?.toDouble() ?? 0);
                }
              }
            }
            result[name] = values;
          }
        }
      }
      return result;
    }

    // Case 2: Map<label, List/Map> where List is list of points or Map is {YYYY-MM: value}
    // Create month index map like 'YYYY-MM' -> idx
    final monthIndex = <String, int>{};
    for (int i = 0; i < months.length; i++) {
      final d = months[i];
      monthIndex['${d.year}-${d.month.toString().padLeft(2, '0')}'] = i;
    }

    int added = 0;
    for (final entry in raw.entries) {
      if (added >= 6) break; // limit the number of lines to keep readable
      final label = entry.key.toString();
      final values = List<double>.filled(months.length, 0);
      final v = entry.value;

      if (v is List) {
        for (final p in v) {
          if (p is Map) {
            final m = Map<String, dynamic>.from(p);
            // date candidates
            final dateStr = (m['date'] ?? m['data'] ?? m['period'] ?? m['mes'] ?? '').toString();
            final year = m['year'] is int ? m['year'] as int : int.tryParse('${m['year'] ?? ''}');
            final month = m['month'] is int ? m['month'] as int : int.tryParse('${m['month'] ?? m['mes'] ?? ''}');
            DateTime? d;
            if (year != null && month != null) {
              d = DateTime(year, month, 1);
            } else if (dateStr.isNotEmpty) {
              final parsed = DateTime.tryParse(dateStr);
              if (parsed != null) d = DateTime(parsed.year, parsed.month, 1);
              if (d == null && dateStr.contains('/')) {
                // try MM/yyyy
                final parts = dateStr.split('/');
                if (parts.length >= 2) {
                  final mm = int.tryParse(parts[0]);
                  final yy = int.tryParse(parts[1]);
                  if (mm != null && yy != null) {
                    final fullYear = yy < 100 ? (2000 + yy) : yy;
                    d = DateTime(fullYear, mm, 1);
                  }
                }
              }
            }
            final key = d != null ? '${d.year}-${d.month.toString().padLeft(2, '0')}' : null;
            final idx = key != null ? monthIndex[key] : null;
            if (idx != null) {
              final num? n = (m['value'] ?? m['amount'] ?? m['consumption'] ?? m['qtd'] ?? m['total']) as num?;
              values[idx] = (n?.toDouble() ?? 0);
            }
          }
        }
        result[label] = values;
        added++;
        continue;
      }

      if (v is Map) {
        final map = Map<String, dynamic>.from(v);
        for (final e in map.entries) {
          final key = e.key.toString(); // expect 'YYYY-MM' or 'YYYY-MM-DD'
          final normalizedKey = key.length >= 7 ? key.substring(0, 7) : key;
          final idx = monthIndex[normalizedKey];
          if (idx != null) {
            final num? n = e.value is num ? e.value as num : num.tryParse('${e.value}');
            values[idx] = (n?.toDouble() ?? 0);
          }
        }
        result[label] = values;
        added++;
        continue;
      }
    }

    return result;
  }

  Widget _buildSectionChart() {
    final months = _monthBuckets();
    // Prefer already filtered by selected sections when possible
    Map<String, dynamic>? filtered = _filteredSectionSeries();

    // If API returns the highcharts-like shape, we shouldn't filter with _filteredSectionSeries
    // because it expects Map<String, dynamic> of series. So if keys are categories/series, use raw.
    if (_sectionSeries != null && _sectionSeries!.containsKey('categories') && _sectionSeries!.containsKey('series')) {
      filtered = _sectionSeries;
    }

    var series = _normalizeSeriesToBuckets(filtered, months);

    // Restrict to selected titles if present and not in filtered map
    if (_selectedSectionIds.isNotEmpty && _consumerSections.isNotEmpty) {
      final selectedTitles = _consumerSections
          .where((s) => _selectedSectionIds.contains((s['id'] as int?) ?? -1))
          .map((s) => s['title']?.toString())
          .whereType<String>()
          .toSet();
      if (selectedTitles.isNotEmpty) {
        series = {
          for (final e in series.entries)
            if (selectedTitles.contains(e.key)) e.key: e.value
        };
      }
    }

    // Ensure we render at least a zero series if empty (e.g., {categories: [], series: []})
    if (series.isEmpty) {
      series = {
        if (_selectedSectionIds.isNotEmpty)
          ...{
            for (final id in _selectedSectionIds)
              (_consumerSections.firstWhere(
                        (s) => (s['id'] as int?) == id,
                        orElse: () => {'title': 'Seção $id'},
                      )['title'] as String): List<double>.filled(months.length, 0)
          }
        else
          'Sem dados': List<double>.filled(months.length, 0),
      };
    }

    return SectionMonthlyChart(months: months, series: series);
  }

  // Removido placeholder não utilizado
}

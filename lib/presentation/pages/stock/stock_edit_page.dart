import 'package:flutter/material.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../core/theme/app_colors.dart';

class StockEditPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const StockEditPage({super.key, required this.item});

  @override
  State<StockEditPage> createState() => _StockEditPageState();
}

class _StockEditPageState extends State<StockEditPage> {
  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _measureCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _expireCtrl; // dd/MM/yyyy

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nameCtrl = TextEditingController(text: (it['name'] ?? '').toString());
    _descCtrl = TextEditingController(text: (it['description'] ?? '').toString());
    _qtyCtrl = TextEditingController(text: (it['currentStock'] ?? it['stock'] ?? '').toString());
    _minCtrl = TextEditingController(text: (it['minimumStock'] ?? it['minStock'] ?? it['minimum_stock'] ?? '').toString());
    _maxCtrl = TextEditingController(text: (it['maximumStock'] ?? it['maxStock'] ?? it['maximum_stock'] ?? '').toString());
    _measureCtrl = TextEditingController(text: (it['measure'] ?? '').toString());
    _typeCtrl = TextEditingController(text: (it['itemType'] ?? '').toString());
    _expireCtrl = TextEditingController(text: _formatDisplayDate((it['expirationDate'] ?? it['expireDate'])?.toString()));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _measureCtrl.dispose();
    _typeCtrl.dispose();
    _expireCtrl.dispose();
    super.dispose();
  }

  // Helpers: date parsing/format
  String _formatDisplayDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      DateTime d;
      if (raw.contains('T')) {
        d = DateTime.parse(raw);
      } else if (raw.contains('-')) {
        final p = raw.split('-');
        if (p.length == 3) {
          d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        } else {
          return raw;
        }
      } else {
        return raw;
      }
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  DateTime? _tryParseDisplayDate(String txt) {
    try {
      final p = txt.split('/');
      if (p.length != 3) return null;
      final d = int.parse(p[0]);
      final m = int.parse(p[1]);
      int y = int.parse(p[2]);
      // Normalize 2-digit years like '27' -> 2027 to avoid sending year '27'
      if (y < 100) y += 2000;
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  String? _dateToIso(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    // Backend expects LocalDateTime. Send midnight to match create-item format.
  return '${y}-${mm}-${dd}T00:00:00';
    }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tryParseDisplayDate(_expireCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      setState(() => _expireCtrl.text = '$dd/$mm/${picked.year}');
    }
  }

  Future<void> _save() async {
    final id = widget.item['id']?.toString() ?? widget.item['itemId']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};

      // Strings
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final measure = _measureCtrl.text.trim();
        // Exemplo futuro: payload['itemTypeId'] = selectedItemTypeId;
      if (name.isNotEmpty) payload['name'] = name;
      if (desc.isNotEmpty) payload['description'] = desc;
      if (measure.isNotEmpty) payload['measure'] = measure;

      // Numbers
      final cur = int.tryParse(_qtyCtrl.text.trim());
      final min = int.tryParse(_minCtrl.text.trim());
      final max = int.tryParse(_maxCtrl.text.trim());
      if (cur != null) payload['currentStock'] = cur;
      if (min != null) payload['minimumStock'] = min;
      if (max != null) payload['maximumStock'] = max;

      // Date
      final d = _tryParseDisplayDate(_expireCtrl.text.trim());
      final iso = _dateToIso(d);
      // Backend expects 'expireDate' (maps to expire_date column); keep camelCase.
      if (iso != null && iso.isNotEmpty) payload['expireDate'] = iso; // Updated to use expireDate

      final api = ItemApiDataSource();
      final updated = await api.updateItemStock(id, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item atualizado')));
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.infoLight.withValues(alpha: 0.8),
                    AppColors.infoLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.infoLight.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (it['name']?.toString() ?? 'Sem nome'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _typeCtrl.text.isNotEmpty ? _typeCtrl.text : (it['itemType']?.toString() ?? '-'),
                          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Product info section
            _sectionCard(
              title: 'Informações do Produto',
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Nome',
                  icon: Icons.badge,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _expireCtrl,
                  label: 'Validade (dd/MM/yyyy)',
                  icon: Icons.event,
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    'Código: ${it['id'] ?? it['itemId'] ?? '-'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stock control section
            _sectionCard(
              title: 'Controle de Estoque',
              icon: Icons.inventory_2,
              children: [
                _buildTextField(
                  controller: _qtyCtrl,
                  label: 'Estoque Atual',
                  icon: Icons.inventory,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _minCtrl,
                        label: 'Estoque Mínimo',
                        icon: Icons.warning_amber,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _maxCtrl,
                        label: 'Estoque Máximo',
                        icon: Icons.check_circle_outline,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _measureCtrl,
                  label: 'Unidade/Medida',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _typeCtrl,
                  label: 'Tipo do Item',
                  icon: Icons.label,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description section
            _sectionCard(
              title: 'Descrição',
              icon: Icons.description,
              children: [
                _buildTextField(
                  controller: _descCtrl,
                  label: 'Descrição do item',
                  icon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.infoLight,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.infoLight.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.infoLight, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.infoLight),
        ),
      ),
    );
  }
}

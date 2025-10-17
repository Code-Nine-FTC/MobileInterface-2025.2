import 'package:flutter/material.dart';
import '../../../data/api/item_api_data_source.dart';

class StockEditPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const StockEditPage({Key? key, required this.item}) : super(key: key);

  @override
  State<StockEditPage> createState() => _StockEditPageState();
}

class _StockEditPageState extends State<StockEditPage> {
  late TextEditingController _qtyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _qtyCtrl = TextEditingController(text: (it['currentStock'] ?? it['stock'] ?? '').toString());
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = widget.item['id']?.toString();
    if (id == null || id.isEmpty) return;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    setState(() => _saving = true);
    try {
      final api = ItemApiDataSource();
      final updated = await api.updateItemStock(id, {'currentStock': qty});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estoque atualizado')));
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
      appBar: AppBar(title: const Text('Editar Estoque')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${it['id'] ?? '-'}'),
            const SizedBox(height: 8),
            Text('Nome: ${it['name'] ?? it['description'] ?? '-'}'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const CircularProgressIndicator() : const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

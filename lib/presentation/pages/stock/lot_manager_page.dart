import 'package:flutter/material.dart';
import '../../../data/api/lot_api_data_source.dart';
import '../../../domain/entities/lot.dart';

class LotManagerPage extends StatefulWidget {
  final String? itemId; // accepts string id from scanner
  final String? itemName;

  const LotManagerPage({super.key, this.itemId, this.itemName});

  @override
  State<LotManagerPage> createState() => _LotManagerPageState();
}

class _LotManagerPageState extends State<LotManagerPage> {
  final _lotApi = LotApiDataSource();
  List<Lot> _lots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = int.tryParse(widget.itemId ?? '');
      if (id == null) throw Exception('ID do item inválido');
      final list = await _lotApi.listLots(itemId: id);
      setState(() => _lots = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Não informado';
    try {
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          return dateString;
        }
      } else {
        return dateString;
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _openAdjustDialog(Lot lot) async {
    final ctrl = TextEditingController();
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Ajustar lote: ${lot.code}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quantidade atual: ${lot.quantityOnHand}'),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ajuste (+/-) (ex: -1 ou 2)',
                  ),
                ),
                if (saving) const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final delta = int.tryParse(ctrl.text.trim()) ?? 0;
                        setState(() => saving = true);
                        try {
                          final updated = await _lotApi.adjustLot(lotId: lot.id, delta: delta);
                          // update local list
                          final i = _lots.indexWhere((l) => l.id == lot.id);
                          if (i >= 0) setState(() => _lots[i] = updated);
                          Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao ajustar lote: $e')));
                        }
                      },
                child: const Text('Aplicar'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName == null ? 'Gerenciar Lotes' : 'Lotes - ${widget.itemName}'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : _lots.isEmpty
                  ? const Center(child: Text('Nenhum lote cadastrado para este item.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (ctx, idx) {
                        final lot = _lots[idx];
                        return ListTile(
                          onTap: () => _openAdjustDialog(lot),
                          title: Text(lot.code.isEmpty ? 'Sem código' : lot.code),
                          subtitle: Text('Validade: ${_formatDate(lot.expireDate)}'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Qtd: ${lot.quantityOnHand}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('ID: ${lot.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: _lots.length,
                    ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/lot_api_data_source.dart';
import '../../../domain/entities/lot.dart';

class StockDetailPage extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? itemData;

  const StockDetailPage({super.key, this.itemId, this.itemData});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  // Services
  final _storage = SecureStorageService();
  final _itemApi = ItemApiDataSource();
  final _lotApi = LotApiDataSource();

  // Item state
  Map<String, dynamic>? _item;
  String? _itemTypeName;
  List<dynamic> _itemLosses = [];

  // UI state
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  String _userRole = '';
  bool _dataChanged = false;

  // Lots state
  List<Lot> _lots = [];
  bool _lotsLoading = false;
  String? _lotsError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _storage.getUser();
      _userRole = user?.role ?? '';
    } catch (_) {}

    // Seed from navigation data if provided
    if (widget.itemData != null) {
      _item = Map<String, dynamic>.from(widget.itemData!);
      _itemTypeName = _item?['itemType']?.toString();
      if (_item?['lossHistory'] is List) {
        _itemLosses = List<dynamic>.from(_item!['lossHistory']);
      }
    }

    final id = _currentItemId();
    if (id != null && widget.itemData == null) {
      await _fetchItem();
    }
    if (id != null) {
      await _fetchLots();
    }

    if (mounted) setState(() => _loading = false);
  }

  String? _currentItemId() {
    if (widget.itemId != null && widget.itemId!.isNotEmpty) return widget.itemId;
    final id = _item?['id']?.toString() ?? _item?['itemId']?.toString();
    return (id != null && id.isNotEmpty) ? id : null;
  }

  Future<void> _fetchItem() async {
    final id = _currentItemId();
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _itemApi.getItemById(id);
      _item = data;
      _itemTypeName = _item?['itemType']?.toString();
      if (_item?['lossHistory'] is List) {
        _itemLosses = List<dynamic>.from(_item!['lossHistory']);
      } else {
        _itemLosses = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchLots() async {
    final id = _currentItemId();
    if (id == null) return;
    setState(() {
      _lotsLoading = true;
      _lotsError = null;
    });
    try {
      final list = await _lotApi.listLots(itemId: int.parse(id));
      setState(() => _lots = list);
    } catch (e) {
      setState(() => _lotsError = e.toString());
    } finally {
      if (mounted) setState(() => _lotsLoading = false);
    }
  }

  Future<void> _quickAdjust(Lot lot, int delta) async {
    try {
      final updated = await _lotApi.adjustLot(lotId: lot.id, delta: delta);
      setState(() {
        final i = _lots.indexWhere((l) => l.id == lot.id);
        if (i >= 0) _lots[i] = updated;
        _dataChanged = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ajustar lote: $e')),
      );
    }
  }

  Future<void> _openCreateLotDialog() async {
    final id = _currentItemId();
    if (id == null) return;

    final codeCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final dateCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Lote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código')),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Validade (yyyy-MM-dd)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final expire = dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim();
              try {
                final lot = await _lotApi.createLot(
                  itemId: int.parse(id),
                  code: code,
                  expireDate: expire,
                  quantity: qty,
                );
                if (!mounted) return;
                setState(() {
                  _lots.insert(0, lot);
                  _dataChanged = true;
                });
                Navigator.pop(ctx);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao criar lote: $e')),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdjustLotDialog(Lot lot) async {
    final deltaCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajustar Lote'),
        content: TextField(
          controller: deltaCtrl,
          decoration: const InputDecoration(labelText: 'Ajuste (+/-)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final delta = int.tryParse(deltaCtrl.text.trim()) ?? 0;
              try {
                final updated = await _lotApi.adjustLot(lotId: lot.id, delta: delta);
                if (!mounted) return;
                setState(() {
                  final i = _lots.indexWhere((l) => l.id == lot.id);
                  if (i >= 0) _lots[i] = updated;
                  _dataChanged = true;
                });
                Navigator.pop(ctx);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao ajustar: $e')),
                );
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando detalhes...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (_error != null) {
      content = Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Ops! Algo deu errado', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  Row(
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
                              _item?['name']?.toString() ?? 'Sem nome',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _itemTypeName ?? _item?['itemType']?.toString() ?? '-',
                              style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _stockStatusCard('Estoque Atual', _item?['currentStock']?.toString() ?? '0', Icons.inventory)),
                        const SizedBox(width: 16),
                        Expanded(child: _stockStatusCard('Unidade', _item?['measure']?.toString() ?? '-', Icons.straighten)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informações do produto
            _sectionCard(
              title: 'Informações do Produto',
              icon: Icons.info_outline,
              children: [
                InkWell(
                  onTap: () => _showQrDialog(context),
                  child: _modernInfoRow('Código', _item?['id']?.toString() ?? '-', Icons.qr_code),
                ),
                _modernInfoRow('Validade', _formatDate(_item?['expirationDate']?.toString()), Icons.event),
              ],
            ),
            const SizedBox(height: 16),

            // Controle de estoque
            _sectionCard(
              title: 'Controle de Estoque',
              icon: Icons.inventory_2,
              children: [
                _modernInfoRow(
                  'Estoque Mínimo',
                  _item?['minimumStock']?.toString() ?? _item?['minStock']?.toString() ?? _item?['minimum_stock']?.toString() ?? 'Não informado',
                  Icons.warning_amber,
                ),
                _modernInfoRow(
                  'Estoque Máximo',
                  _item?['maximumStock']?.toString() ?? _item?['maxStock']?.toString() ?? _item?['maximum_stock']?.toString() ?? 'Não informado',
                  Icons.check_circle_outline,
                ),
                _modernInfoRow('Tipo do Item', _itemTypeName ?? _item?['itemType']?.toString() ?? 'Não informado', Icons.label),
              ],
            ),
            const SizedBox(height: 16),

            if ((_item?['description']?.toString().isNotEmpty ?? false))
              _sectionCard(
                title: 'Descrição',
                icon: Icons.description,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _item?['description']?.toString() ?? '',
                      style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Histórico de perdas
            _sectionCard(
              title: 'Histórico de Perdas',
              icon: Icons.remove_circle_outline,
              children: _itemLosses.isEmpty
                  ? [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text('Nenhuma perda registrada para este item.', style: TextStyle(color: Colors.grey[700])),
                      ),
                    ]
                  : _itemLosses.map((loss) {
                      final date = loss['createDate']?.toString() ?? loss['create_date']?.toString();
                      final qty = loss['lostQuantity']?.toString() ?? loss['lost_quantity']?.toString() ?? '-';
                      final reason = loss['reason']?.toString() ?? '-';
                      final recordedBy = loss['recordedByName']?.toString() ?? loss['recorded_by_name']?.toString() ?? '-';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reason, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('Registrado por: $recordedBy', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(_formatDate(date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 20),

            if (_userRole == 'ADMIN' || _userRole == 'MANAGER')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/register_loss',
                      arguments: {
                        'itemId': _item?['id']?.toString() ?? _item?['itemId']?.toString(),
                        'itemName': _item?['name']?.toString() ?? 'Item sem nome',
                      },
                    );
                    if (!mounted) return;
                    if (result == true || (result is Map && result.containsKey('createdLoss'))) {
                      setState(() => _dataChanged = true);
                      if (result is Map && result['createdLoss'] != null) {
                        try {
                          final created = Map<String, dynamic>.from(result['createdLoss']);
                          _itemLosses.insert(0, created);
                          if (_item != null && _item!.containsKey('lossHistory') && _item!['lossHistory'] is List) {
                            final list = _item!['lossHistory'] as List;
                            list.insert(0, created);
                            _item!['lossHistory'] = list;
                          }
                          final current = _item?['currentStock'];
                          if (current != null) {
                            try {
                              final intCur = int.tryParse(current.toString()) ?? (current is int ? current : 0);
                              final lost = int.tryParse(created['lostQuantity']?.toString() ?? '') ?? (created['lost_quantity'] ?? 0) as int;
                              _item!['currentStock'] = (intCur - lost).toString();
                            } catch (_) {}
                          }
                        } catch (e) {
                          // ignore
                        }
                      }
                      try {
                        await _fetchItem();
                      } catch (_) {}
                      if (mounted) Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.warning_amber_rounded, size: 22),
                  label: const Text('Registrar Perda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.red.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_userRole == 'ADMIN' || _userRole == 'MANAGER') const SizedBox(height: 20),

            // Lotes
            _sectionCard(
              title: 'Lotes',
              icon: Icons.qr_code_2,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentItemId() == null
                            ? 'ID do item não disponível nesta tela. Abra o item via lista de estoque para gerenciar lotes.'
                            : 'Gerencie os lotes deste item',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateLotDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Lote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.infoLight,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentItemId() != null) ...[
                  if (_lotsLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
                  else if (_lotsError != null)
                    Text('Erro ao carregar lotes: $_lotsError', style: const TextStyle(color: Colors.red))
                  else if (_lots.isEmpty)
                    Text('Nenhum lote cadastrado para este item.', style: TextStyle(color: Colors.grey[600]))
                  else
                    Column(
                      children: _lots.map((lot) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Código: ${lot.code}', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('Validade: ${lot.expireDate == null || lot.expireDate!.isEmpty ? '—' : lot.expireDate!}')
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Qtd: ${lot.quantityOnHand}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        IconButton(
                                          tooltip: 'Baixar 1',
                                          onPressed: () => _quickAdjust(lot, -1),
                                          icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          tooltip: 'Adicionar 1',
                                          onPressed: () => _quickAdjust(lot, 1),
                                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          tooltip: 'Ajustar...',
                                          onPressed: () => _openAdjustLotDialog(lot),
                                          icon: const Icon(Icons.tune, color: Colors.blueGrey, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ]
              ],
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_dataChanged);
        return false;
      },
      child: StandardScreen(
        title: 'Detalhes do Produto',
        showBackButton: true,
        bottomNavigationBar: CustomNavbar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        child: content,
      ),
    );
  }

  // ----------------- UI helpers -----------------
  Widget _stockStatusCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
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

  Widget _modernInfoRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (statusColor ?? AppColors.infoLight).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor ?? AppColors.infoLight, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: statusColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '-') return 'Não informado';
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

  Future<void> _showQrDialog(BuildContext context) async {
    final code = _item?['qrCode']?.toString() ?? '-';
    final name = _item?['name']?.toString() ?? 'Sem nome';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(data: code, size: 160),
                const SizedBox(height: 12),
              ],
            ),
          ),
          actions: [
            TextButton.icon(onPressed: () => _shareQr(code, name), icon: const Icon(Icons.share), label: const Text('Compartilhar')),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _printQrAsPdf(code, name);
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
          ],
        );
      },
    );
  }

  Future<void> _shareQr(String code, String name) async {
    try {
      final doc = pw.Document();
      final qrPainter = QrPainter(data: code, version: QrVersions.auto, gapless: false);
      final byteData = await qrPainter.toImageData(300);
      final bytes = byteData!.buffer.asUint8List();
      final image = pw.MemoryImage(bytes);

      doc.addPage(
        pw.Page(
          build: (context) => pw.Column(children: [
            pw.Text(name, style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 12),
            pw.Image(image, width: 200, height: 200),
          ]),
        ),
      );

      final pdfBytes = await doc.save();
      final xfile = XFile.fromData(pdfBytes, name: '${name.replaceAll(' ', '_')}_qr.pdf', mimeType: 'application/pdf');
      await Share.shareXFiles([xfile], text: 'Produto: $name');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
    }
  }

  Future<void> _printQrAsPdf(String code, String name) async {
    try {
      await Printing.layoutPdf(onLayout: (format) async {
        final doc = pw.Document();
        final qrPainter = QrPainter(data: code, version: QrVersions.auto, gapless: false);
        final byteData = await qrPainter.toImageData(300);
        final bytes = byteData!.buffer.asUint8List();
        final image = pw.MemoryImage(bytes);
        doc.addPage(
          pw.Page(
            build: (context) => pw.Column(children: [
              pw.Text(name, style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 12),
              pw.Image(image, width: 200, height: 200),
            ]),
          ),
        );
        return doc.save();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao imprimir: $e')));
    }
  }
}

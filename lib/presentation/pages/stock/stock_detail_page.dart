import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/item_type_api_data_source.dart';
import '../../../data/api/lot_api_data_source.dart';
import '../../../domain/entities/lot.dart';
import '../../components/navBar.dart';

class StockDetailPage extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? itemData;
  const StockDetailPage({super.key, this.itemId, this.itemData});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _item;
  bool _loading = true;
  String? _error;
  String? _itemTypeName;
  final SecureStorageService _storageService = SecureStorageService();
  // Lots state
  List<Lot> _lots = [];
  bool _lotsLoading = false;
  String? _lotsError;

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _item = widget.itemData;
      _loading = false;
      _fetchAdditionalData();
      _fetchLots();
    } else {
      _fetchItem();
    }
  }

  Future<void> _quickAdjust(Lot lot, int delta) async {
    try {
      final api = LotApiDataSource();
      await api.adjustLot(lotId: lot.id, delta: delta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(delta > 0 ? 'Adicionado 1 ao lote' : 'Removido 1 do lote')),
      );
      await _fetchLots();
      await _fetchItem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ajustar lote: $e')),
      );
    }
  }

  Future<void> _fetchAdditionalData() async {
    if (_item == null) return;

    String? itemTypeName;
    if (_item!['itemTypeId'] != null) {
      try {
        final itemTypeApi = ItemTypeApiDataSource();
        final itemType = await itemTypeApi.getItemTypeById(
          _item!['itemTypeId'].toString(),
        );
        itemTypeName = itemType['name'];
      } catch (e) {
        print('Erro ao buscar tipo de item: $e');
        itemTypeName = 'Tipo não encontrado';
      }
    }

    setState(() {
      _itemTypeName = itemTypeName;
    });
  }

  Future<void> _fetchItem() async {
    if (widget.itemId == null || widget.itemId!.isEmpty) {
      setState(() {
        _error = 'ID do item não fornecido';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Buscar dados do item
      final api = ItemApiDataSource();
      final data = await api.getItemById(widget.itemId!);

      // Buscar nome do tipo de item se houver itemTypeId
      String? itemTypeName;
      if (data['itemTypeId'] != null) {
        try {
          final itemTypeApi = ItemTypeApiDataSource();
          final itemType = await itemTypeApi.getItemTypeById(
            data['itemTypeId'].toString(),
          );
          itemTypeName = itemType['name'];
        } catch (e) {
          print('Erro ao buscar tipo de item: $e');
          itemTypeName = 'Tipo não encontrado';
        }
      }

      setState(() {
        _item = data;
        _itemTypeName = itemTypeName;
        _loading = false;
      });
      await _fetchLots();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _currentItemId() {
    final dynamic id1 = _item?['id'];
    final dynamic id2 = _item?['itemId'];
    final dynamic id3 = _item?['item_id'];
    final String? id4 = widget.itemId;
    int? parse(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    return parse(id1) ?? parse(id2) ?? parse(id3) ?? parse(id4);
  }

  Future<void> _fetchLots() async {
    final itemId = _currentItemId();
    if (itemId == null) return;
    setState(() {
      _lotsLoading = true;
      _lotsError = null;
    });
    try {
      final api = LotApiDataSource();
      final lots = await api.listLots(itemId: itemId);
      setState(() {
        _lots = lots;
        _lotsLoading = false;
      });
    } catch (e) {
      setState(() {
        _lotsLoading = false;
        _lotsError = e.toString();
      });
    }
  }

  Future<void> _openCreateLotDialog() async {
    final itemId = _currentItemId();
    if (itemId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível identificar o ID numérico do item para criar lote.'),
      ));
      return;
    }
    final codeController = TextEditingController();
    final expireController = TextEditingController();
    final qtyController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlg) {
            return AlertDialog(
              title: const Text('Novo Lote'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Código (obrigatório)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
                      ),
                      TextFormField(
                        controller: expireController,
                        decoration: const InputDecoration(labelText: 'Validade (yyyy-MM-dd, opcional)'),
                      ),
                      TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantidade (>= 0)'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Quantidade inválida';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDlg(() => saving = true);
                          try {
                            final lotsApi = LotApiDataSource();
                            await lotsApi.createLot(
                              itemId: itemId,
                              code: codeController.text.trim(),
                              expireDate: expireController.text.trim().isEmpty ? null : expireController.text.trim(),
                              quantity: int.parse(qtyController.text.trim()),
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lote criado com sucesso')));
                            await _fetchLots();
                            await _fetchItem();
                          } catch (e) {
                            setDlg(() => saving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar lote: $e')));
                          }
                        },
                  child: saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAdjustLotDialog(Lot lot) async {
    final deltaController = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar Lote ${lot.code}'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: deltaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Delta (+ entrada, - baixa)'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final delta = int.tryParse(deltaController.text.trim()) ?? 0;
              try {
                final api = LotApiDataSource();
                await api.adjustLot(lotId: lot.id, delta: delta);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lote ajustado')));
                await _fetchLots();
                await _fetchItem();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao ajustar lote: $e')));
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: StandardScreen(
        title: 'Detalhes do Produto',
        showBackButton: true, // Adicione o botão voltar
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando detalhes...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ops! Algo deu errado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erro ao carregar: $_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchItem,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.infoLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _item == null
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.search_off,
                          color: Colors.orange,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Item não encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O produto que você procura não existe ou foi removido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com imagem/ícone e informações principais
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
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _item?['name']?.toString() ?? 'Sem nome',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Status do estoque
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _stockStatusCard(
                                    'Estoque Atual',
                                    _item?['currentStock']?.toString() ?? '0',
                                    Icons.inventory,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _stockStatusCard(
                                    'Unidade',
                                    _item?['measure']?.toString() ?? '-',
                                    Icons.straighten,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Informações técnicas
                    _sectionCard(
                      title: 'Informações do Produto',
                      icon: Icons.info_outline,
                      children: [
                        // Tornar o código clicável para abrir o popup com QR
                        InkWell(
                          onTap: () => _showQrDialog(context),
                          child: _modernInfoRow(
                            'Código',
                            _item?['id']?.toString() ?? '-',
                            Icons.qr_code,
                          ),
                        ),
                        _modernInfoRow(
                          'Validade',
                          _formatDate(_item?['expirationDate']?.toString()),
                          Icons.event,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Controle de estoque
                    _sectionCard(
                      title: 'Controle de Estoque',
                      icon: Icons.inventory_2,
                      children: [
                        // Fornecedor removido do domínio
                        _modernInfoRow(
                          'Estoque Mínimo',
                          _item?['minimumStock']?.toString() ??
                              _item?['minStock']?.toString() ??
                              _item?['minimum_stock']?.toString() ??
                              'Não informado',
                          Icons.warning_amber,
                        ),
                        _modernInfoRow(
                          'Estoque Máximo',
                          _item?['maximumStock']?.toString() ??
                              _item?['maxStock']?.toString() ??
                              _item?['maximum_stock']?.toString() ??
                              'Não informado',
                          Icons.check_circle_outline,
                        ),
                        _modernInfoRow(
                          'Tipo do Item',
                          _itemTypeName ??
                              _item?['itemType']?.toString() ??
                              'Não informado',
                          Icons.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descrição se houver
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
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Botões de ação ocultados a pedido: Editar e Movimentar
                    const SizedBox.shrink(),
                    const SizedBox(height: 16),

                    // Seção de Lotes
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
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
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
                                      // Esquerda: código e validade
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Código: ${lot.code}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Validade: ${lot.expireDate == null || lot.expireDate!.isEmpty ? '—' : lot.expireDate!}'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Direita: quantidade e ações compactas
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 140),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Qtd: ${lot.quantityOnHand}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
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
              ),
      ),
    );
  }

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

  Widget _modernInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
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
              color: (statusColor ?? AppColors.infoLight).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor ?? AppColors.infoLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '-') {
      return 'Não informado';
    }

    try {
      // Tenta diferentes formatos de data
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          return dateString;
        }
      } else {
        return dateString;
      }

      // Formata para dd/MM/yyyy
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showQrDialog(BuildContext context) async {
  // O backend já retorna o campo `qrCode` no formato esperado (ex: "/items?code=...").
  final code = _item?['qrCode']?.toString() ?? '-';
    final name = _item?['name']?.toString() ?? 'Sem nome';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 300,
            child: Builder(
              builder: (context) {
                // Constrói o widget do QR de forma síncrona para evitar que LayoutBuilder
                // seja executado durante cálculos intrínsecos do AlertDialog.
                Widget qrChild;
                try {
                  qrChild = QrImageView(
                    data: code,
                    size: 160.0,
                  );
                } catch (e) {
                  print('[StockDetail] Erro ao gerar QR: $e');
                  qrChild = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text('Não foi possível gerar o QR.'),
                      const SizedBox(height: 8),
                      Text('Detalhes: $e', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    qrChild,
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _shareQr(code, name),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _printQrAsPdf(code, name);
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareQr(String code, String name) async {
    try {
      // Gera o PDF na memória (mesma lógica de _printQrAsPdf, mas sem abrir diálogo de impressão)
      final doc = pw.Document();

      // Renderiza o QR em bytes
      final qrPainter = QrPainter(data: code, version: QrVersions.auto, gapless: false);
      final byteData = await qrPainter.toImageData(300);
      final bytes = byteData!.buffer.asUint8List();
      final image = pw.MemoryImage(bytes);

      doc.addPage(pw.Page(build: (context) {
        return pw.Column(children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 12),
          pw.Image(image, width: 200, height: 200),
        ]);
      }));

      final pdfBytes = await doc.save();

      // Cria um XFile em memória e compartilha
      final xfile = XFile.fromData(
        pdfBytes,
        name: '${name.replaceAll(' ', '_')}_qr.pdf',
        mimeType: 'application/pdf',
      );

      await Share.shareXFiles([xfile], text: 'Produto: $name');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar: $e')),
      );
    }
  }

  Future<void> _printQrAsPdf(String code, String name) async {
    try {
      // Gera um PDF simples com o QR usando o pacote printing/pdf
      await Printing.layoutPdf(onLayout: (format) async {
        final doc = pw.Document();

        // Renderiza o QR em bytes
  final qrPainter = QrPainter(data: code, version: QrVersions.auto, gapless: false);
        final byteData = await qrPainter.toImageData(300);
        final bytes = byteData!.buffer.asUint8List();

        final image = pw.MemoryImage(bytes);

        doc.addPage(pw.Page(build: (context) {
          return pw.Column(children: [
            pw.Text(name, style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 12),
            pw.Image(image, width: 200, height: 200),
          ]);
        }));

        return doc.save();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e')),
      );
    }
  }
}

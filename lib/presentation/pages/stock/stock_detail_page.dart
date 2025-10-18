import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/supplier_api_data_source.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/item_type_api_data_source.dart';
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
  String? _supplierName;
  String? _itemTypeName;
  List<Map<String, dynamic>> _itemLosses = [];
  final SecureStorageService _storageService = SecureStorageService();
  String? _userRole;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchItem();
  }

  Future<void> _loadUserRole() async {
    final user = await _storageService.getUser();
    setState(() {
      _userRole = user?.role;
    });
  }

  Future<void> _fetchAdditionalData() async {
    if (_item == null) return;

    String? supplierName;
    if (_item!['supplierId'] != null) {
      try {
        final supplierApi = SupplierApiDataSource();
        final supplier = await supplierApi.getSupplierById(
          _item!['supplierId'].toString(),
        );
        supplierName = supplier['name'];
      } catch (e) {
        print('Erro ao buscar fornecedor: $e');
        supplierName = 'Fornecedor não encontrado';
      }
    }

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
      _supplierName = supplierName;
      _itemTypeName = itemTypeName;
    });
  }

  Future<void> _fetchItem() async {
    final targetId = (widget.itemId != null && widget.itemId!.isNotEmpty)
        ? widget.itemId!
        : (widget.itemData != null 
            ? (widget.itemData!['id']?.toString() ?? widget.itemData!['itemId']?.toString())
            : (_item != null 
                ? (_item!['id']?.toString() ?? _item!['itemId']?.toString())
                : null));

    if (targetId == null || targetId.isEmpty) {
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
      final data = await api.getItemById(targetId);

      // Buscar nome do fornecedor se houver supplierId
      String? supplierName;
      if (data['supplierId'] != null) {
        try {
          final supplierApi = SupplierApiDataSource();
          final supplier = await supplierApi.getSupplierById(
            data['supplierId'].toString(),
          );
          supplierName = supplier['name'];
        } catch (e) {
          print('Erro ao buscar fornecedor: $e');
          supplierName = 'Fornecedor não encontrado';
        }
      }

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
        _supplierName = supplierName;
        _itemTypeName = itemTypeName;
        _loading = false;
      });

      if (data.containsKey('lossHistory') && data['lossHistory'] is List) {
        final list = List<Map<String, dynamic>>.from(
          (data['lossHistory'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e})
        );
        setState(() {
          _itemLosses = list;
        });
      } else {
        await _fetchItemLosses();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchItemLosses() async {
    try {
      if (_item == null) return;
      final api = ItemApiDataSource();
      final losses = await api.getItemLosses(itemId: _item!['id']?.toString() ?? _item!['itemId']?.toString());
      setState(() {
        _itemLosses = losses;
      });
    } catch (e) {
      print('Erro ao buscar perdas do item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_dataChanged);
        return false;
      },
      child: Scaffold(
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
          showBackButton: true,
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
                                              Text(
                                                _supplierName ??
                                                    _item?['supplierName']?.toString() ??
                                                    'Fornecedor não informado',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                ),
                                              ),
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
                                  _modernInfoRow(
                                    'Código',
                                    _item?['id']?.toString() ?? '-',
                                    Icons.qr_code,
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
                                  _modernInfoRow(
                                    'Fornecedor',
                                    _supplierName ??
                                        _item?['supplierName']?.toString() ??
                                        'Não informado',
                                    Icons.business,
                                  ),
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

                              // Histórico de Perdas
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
                                          child: Text(
                                            'Nenhuma perda registrada para este item.',
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
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
                                                    Text(
                                                      reason,
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Registrado por: $recordedBy',
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    qty,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _formatDate(date),
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                  ),
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
                                          'itemId': _item!['id']?.toString() ??
                                              _item!['itemId']?.toString(),
                                          'itemName': _item!['name']?.toString() ??
                                              'Item sem nome',
                                        },
                                      );

                                      if (result == true || (result is Map && result.containsKey('createdLoss'))) {
                                        setState(() {
                                          _dataChanged = true;
                                        });

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
                                                final intCur = int.tryParse(current.toString()) ?? current as int;
                                                final lost = int.tryParse(created['lostQuantity']?.toString() ?? '') ?? (created['lost_quantity'] ?? 0) as int;
                                                _item!['currentStock'] = (intCur - lost).toString();
                                              } catch (_) {
                                              }
                                            }
                                          } catch (e) {
                                            print('Erro ao aplicar perda sintética localmente: $e');
                                          }
                                        }

                                        try {
                                          await _fetchItem();
                                        } catch (e) {
                                          print('Erro ao atualizar item apos perda: $e');
                                        }
                                        if (mounted) Navigator.of(context).pop(true);
                                      }
                                    },
                                    icon: const Icon(Icons.warning_amber_rounded, size: 22),
                                    label: const Text(
                                      'Registrar Perda',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: Colors.red.withValues(alpha: 0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                              if (_userRole == 'ADMIN' || _userRole == 'MANAGER')
                                const SizedBox(height: 20),

                              const SizedBox.shrink(),
                            ],
                          ),
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
}

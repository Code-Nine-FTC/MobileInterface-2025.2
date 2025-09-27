
import 'package:flutter/material.dart';
import '../../../domain/entities/order_item_response.dart';
import '../../../domain/entities/order.dart';
import '../../components/standartScreen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/order_api_data_source.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/supplier_api_data_source.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../components/navBar.dart';

  class OrderDetailPage extends StatefulWidget {
    final int orderId;
    const OrderDetailPage({super.key, required this.orderId});

    @override
    State<OrderDetailPage> createState() => _OrderDetailPageState();
  }

  class _OrderDetailPageState extends State<OrderDetailPage> {
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  List<OrderItemResponse> _orderItems = [];
  Future<void> _approveOrder() async {
    setState(() => _isLoading = true);
    final success = await _orderApi.approveOrder(_order!.id);
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido aprovado!')));
      await _loadOrderDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao aprovar pedido.')));
    }
  }


  Future<void> _completeOrder() async {
    setState(() => _isLoading = true);
    final success = await _orderApi.completeOrder(_order!.id);
    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido completado!')));
      await _loadOrderDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao completar pedido.')));
    }
  }

  Future<void> _showEditItemsDialog() async {
    if (_order == null) return;
    // Carrega todos os itens disponíveis do sistema (igual ao cadastro)
    final storage = SecureStorageService();
    final user = await storage.getUser();
    final itemApi = ItemApiDataSource();
    String? effectiveSectionId;
    if (user?.role == 'ADMIN') {
      effectiveSectionId = null;
    } else {
      effectiveSectionId = user?.sessionId;
    }
    final allItems = await itemApi.getItems(sectionId: effectiveSectionId, userRole: user?.role);
    // Mapeia nomes e ids
    final Map<int, String> itemNames = {
      for (var item in allItems)
        (item['itemId'] ?? item['id']) is int
          ? (item['itemId'] ?? item['id']) as int
          : int.tryParse((item['itemId'] ?? item['id']).toString()) ?? -1:
        (item['name']?.toString() ?? 'Item sem nome')
    };
    final availableItems = itemNames.keys.where((id) => id != -1).toList();
    // Inicializa mapa de quantidades reais dos itens do pedido
    Map<int, int> itemQuantities = {};
    for (final item in _orderItems) {
      itemQuantities[item.id] = item.quantity;
    }
    final result = await showDialog<Map<int, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Editar Itens do Pedido',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableItems.length,
                        itemBuilder: (context, index) {
                          final id = availableItems[index];
                          final isSelected = itemQuantities.containsKey(id);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.withOpacity(0.07) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) async {
                                if (value == true) {
                                  int tempQty = itemQuantities[id] ?? 1;
                                  final qty = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Quantidade para ${itemNames[id] ?? 'Item'}'),
                                        content: TextFormField(
                                          initialValue: tempQty.toString(),
                                          keyboardType: TextInputType.number,
                                          autofocus: true,
                                          onChanged: (v) {
                                            tempQty = int.tryParse(v) ?? 1;
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, tempQty),
                                            child: const Text('Salvar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (qty != null && qty > 0) {
                                    setDialogState(() {
                                      itemQuantities[id] = qty;
                                    });
                                  }
                                } else {
                                  setDialogState(() {
                                    itemQuantities.remove(id);
                                  });
                                }
                              },
                              activeColor: Colors.blue,
                              title: Text(
                                '${itemNames[id] ?? 'Item $id'}${isSelected ? '  x${itemQuantities[id]}' : ''}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                itemQuantities.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, itemQuantities),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Salvar (${itemQuantities.length})'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      await _updateOrderItems(result);
    }
  }

  Future<void> _updateOrderItems(Map<int, int> itemQuantities) async {
    try {
      setState(() => _isLoading = true);
      // Envia atualização dos itens para o backend
      final success = await _orderApi.updateOrderItems(_order!.id, itemQuantities);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itens atualizados!')));
        await _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar itens no servidor.')));
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar itens: $e')));
    }
  }
  Future<void> _showEditStatusDialog() async {
    if (_order == null) return;
    final statusOptions = [

      {'value': 'APPROVED', 'label': 'Aprovado', 'icon': Icons.check_circle, 'color': Colors.green},
      {'value': 'PROCESSING', 'label': 'Processando', 'icon': Icons.settings, 'color': Colors.blue},
      {'value': 'COMPLETED', 'label': 'Completo', 'icon': Icons.done_all, 'color': Colors.purple},
      {'value': 'CANCELLED', 'label': 'Cancelado', 'icon': Icons.cancel, 'color': Colors.red},
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Editar Status do Pedido'),
        children: [
          ...statusOptions.map((opt) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, opt['value'] as String),
                child: Row(
                  children: [
                    Icon(opt['icon'] as IconData, color: opt['color'] as Color),
                    const SizedBox(width: 12),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        color: opt['color'] as Color,
                        fontWeight: _order!.status == opt['value'] ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    if (_order!.status == opt['value'])
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Colors.green, size: 18),
                      ),
                  ],
                ),
              ))
        ],
      ),
    );
    if (result != null && result != _order!.status) {
      await _updateOrderStatus(result);
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      setState(() => _isLoading = true);
      final updatedOrder = await _orderApi.updateOrderStatus(orderId: _order!.id, status: newStatus);
      setState(() {
        _order = updatedOrder;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status atualizado para $newStatus!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('Tem certeza que deseja cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, cancelar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _orderApi.cancelOrder(_order!.id);
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado com sucesso!')),
        );
        await _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cancelar pedido.')),
        );
      }
    }
  }
  User? _currentUser;
    int _selectedIndex = 0;
    final OrderApiDataSource _orderApi = OrderApiDataSource();
    final SupplierApiDataSource _supplierApi = SupplierApiDataSource();
    Order? _order;
    bool _isLoading = true;
    String? _error;
    Map<int, String> _itemNames = {};
  // Removido campo _supplierNames, agora usamos supplierName dos itens

    @override
    void initState() {
      super.initState();
      _loadUserAndOrderDetails();
    }

    Future<void> _loadUserAndOrderDetails() async {
      final storage = SecureStorageService();
      final user = await storage.getUser();
      setState(() {
        _currentUser = user;
      });
      await _loadOrderDetails();
    }

    Future<void> _loadOrderDetails() async {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final order = await _orderApi.getOrderById(widget.orderId);
        if (order == null) throw Exception('Pedido não encontrado');
        final orderItems = await _orderApi.getOrderItemsByOrderId(order.id);
        // Mantém busca de fornecedores se necessário
        final supplierNames = <int, String>{};
        for (final supplierId in order.supplierIds) {
          try {
            final supplier = await _supplierApi.getSupplierById(supplierId.toString());
            String name;
            if (supplier['name'] != null && supplier['name'].toString().trim().isNotEmpty) {
              name = supplier['name'].toString();
            } else if (supplier.isEmpty) {
              name = 'Fornecedor não encontrado (ID $supplierId)';
            } else {
              name = supplier.toString();
            }
            supplierNames[supplierId] = name;
          } catch (e) {
            supplierNames[supplierId] = 'Fornecedor não encontrado (ID $supplierId)';
          }
        }
        setState(() {
          _order = order;
          _orderItems = orderItems;
          _isLoading = false;
          print('Itens carregados para o pedido:');
          print(_orderItems);
        });
      } catch (e) {
        setState(() {
          _error = 'Erro ao carregar detalhes do pedido: $e';
          _isLoading = false;
        });
      }
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
          title: _order != null ? 'Pedido #${_order!.id}' : 'Detalhes do Pedido',
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando detalhes...', style: TextStyle(color: Colors.grey)),
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
                              color: Colors.red.withOpacity(0.1),
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
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ops! Algo deu errado',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Erro ao carregar: ',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              _error ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[600]),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadOrderDetails,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.infoLight,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _order == null
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
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
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Icon(Icons.search_off, color: Colors.orange, size: 48),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Pedido não encontrado',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'O pedido que você procura não existe ou foi removido.',
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
                              // Header com status e datas
                              _buildOrderHeader(),
                              const SizedBox(height: 24),
                              // Card de itens do pedido
                              _buildOrderItemsCard(),
                              const SizedBox(height: 24),
                              // Card de fornecedores
                              _buildInfoCards(),
                              const SizedBox(height: 24),
                              if (_currentUser != null && (_currentUser!.role == 'ADMIN' || _currentUser!.role == 'MANAGER'))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _completeOrder,
                                          icon: const Icon(Icons.done_all),
                                          label: const Text('Concluir'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _approveOrder,
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Aprovar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _cancelOrder,
                                          icon: const Icon(Icons.cancel),
                                          label: const Text('Cancelar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.black87),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'status':
                                              _showEditStatusDialog();
                                              break;
                                            case 'itens':
                                              _showEditItemsDialog();
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'status',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.edit, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Editar Status'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'itens',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.edit_note, color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('Editar Itens'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
        ),
      );
    }

    Widget _buildOrderHeader() {
      final order = _order!;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.infoLight.withOpacity(0.8),
              AppColors.infoLight,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.infoLight.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment,
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
                        'Status: ${order.status}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data de retirada: ${_formatDate(order.withdrawDay)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ATIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Criado em',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.update,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(order.lastUpdate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Última atualização',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildInfoCards() {
    // Extrai nomes únicos dos fornecedores dos itens do pedido
  final fornecedoresUnicos = _orderItems
    .map((item) => item.supplierName)
    .whereType<String>()
    .map((name) => name.trim())
    .where((name) => name.isNotEmpty)
    .toSet()
    .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.business,
                color: AppColors.infoLight,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Fornecedores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          fornecedoresUnicos.isEmpty
              ? const Text('Nenhum fornecedor vinculado.')
              : Wrap(
                  children: fornecedoresUnicos.map((name) => Chip(
                    label: Text(
                      name,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    backgroundColor: Colors.purple.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )).toList(),
                ),
        ],
      ),
    );
    }

  Widget _buildOrderItemsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.inventory_2, color: Colors.blue),
                SizedBox(width: 8),
                Text('Itens do Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            if (_orderItems.isEmpty)
              const Text('Nenhum item vinculado.', style: TextStyle(color: Colors.grey)),
            for (final item in _orderItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.name)),
                    Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (item.unit != null) ...[
                      const SizedBox(width: 4),
                      Text(item.unit!, style: const TextStyle(color: Colors.grey)),
                    ]
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  }
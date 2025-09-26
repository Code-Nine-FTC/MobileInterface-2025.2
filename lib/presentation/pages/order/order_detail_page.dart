import 'package:flutter/material.dart';
import '../../../domain/entities/order.dart';
import '../../components/standartScreen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/api/order_api_data_source.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/supplier_api_data_source.dart';

  class OrderDetailPage extends StatefulWidget {
    final int orderId;
    const OrderDetailPage({super.key, required this.orderId});

    @override
    State<OrderDetailPage> createState() => _OrderDetailPageState();
  }

  class _OrderDetailPageState extends State<OrderDetailPage> {
    final OrderApiDataSource _orderApi = OrderApiDataSource();
    final ItemApiDataSource _itemApi = ItemApiDataSource();
    final SupplierApiDataSource _supplierApi = SupplierApiDataSource();
    Order? _order;
    bool _isLoading = true;
    String? _error;
    Map<int, String> _itemNames = {};
    Map<int, String> _supplierNames = {};

    @override
    void initState() {
      super.initState();
      _loadOrderDetails();
    }

    Future<void> _loadOrderDetails() async {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final order = await _orderApi.getOrderById(widget.orderId);
        if (order == null) throw Exception('Pedido não encontrado');
        final itemNames = <int, String>{};
        for (final itemId in order.itemIds) {
          try {
            final item = await _itemApi.getItemById(itemId.toString());
            print('DEBUG getItemById($itemId): $item');
            String name;
            if (item['name'] != null && item['name'].toString().trim().isNotEmpty) {
              name = item['name'].toString();
            } else if (item.isEmpty) {
              name = 'Item não encontrado (ID $itemId)';
            } else {
              name = item.toString(); // Mostra o JSON bruto para debug
            }
            itemNames[itemId] = name;
          } catch (e) {
            print('ERRO getItemById($itemId): $e');
            itemNames[itemId] = 'Item não encontrado (ID $itemId)';
          }
        }
        final supplierNames = <int, String>{};
        for (final supplierId in order.supplierIds) {
          try {
            final supplier = await _supplierApi.getSupplierById(supplierId.toString());
            print('DEBUG getSupplierById($supplierId): $supplier');
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
            print('ERRO getSupplierById($supplierId): $e');
            supplierNames[supplierId] = 'Fornecedor não encontrado (ID $supplierId)';
          }
        }
        setState(() {
          _order = order;
          _itemNames = itemNames;
          _supplierNames = supplierNames;
          _isLoading = false;
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
                              // Cards de informações
                              _buildInfoCards(),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  label: const Text('Editar Pedido'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.infoLight,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailPage(orderId: _order!.id),
                                      ),
                                    );
                                  },
                                ),
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
      final order = _order!;
      return Column(
        children: [
          Container(
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
                      Icons.inventory_2,
                      color: AppColors.infoLight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Itens do Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                order.itemIds.isEmpty
                    ? const Text('Nenhum item vinculado.')
                    : Wrap(
                        spacing: 8,
                        children: order.itemIds.map((id) => Chip(
                          label: Text(
                            _itemNames[id] ?? 'Item $id',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                order.supplierIds.isEmpty
                    ? const Text('Nenhum fornecedor vinculado.')
                    : Wrap(
                       children: order.supplierIds.map((id) => Chip(
                          label: Text(
                            _supplierNames[id] ?? 'Fornecedor $id',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          backgroundColor: Colors.purple.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )).toList(),
                      ),
              ],
            ),
          ),
        ],
      );
    }

    String _formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

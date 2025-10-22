import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/navBar.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/order_api_data_source.dart';
import '../../../domain/entities/order.dart';

// Centralização dos status
class OrderStatusInfo {
  final String english;
  final String portuguese;
  final Color color;
  const OrderStatusInfo({required this.english, required this.portuguese, required this.color});
}

const Map<String, OrderStatusInfo> kOrderStatusMap = {
  'pending': OrderStatusInfo(english: 'pending', portuguese: 'Pendente', color: Colors.orange),
  'processing': OrderStatusInfo(english: 'processing', portuguese: 'Processando', color: Colors.blue),
  'approved': OrderStatusInfo(english: 'approved', portuguese: 'Aprovado', color: Colors.teal),
  'completed': OrderStatusInfo(english: 'completed', portuguese: 'Concluído', color: Colors.green),
  'cancelled': OrderStatusInfo(english: 'cancelled', portuguese: 'Cancelado', color: Colors.red),
  'canceled': OrderStatusInfo(english: 'canceled', portuguese: 'Cancelado', color: Colors.red),
  'in_progress': OrderStatusInfo(english: 'in_progress', portuguese: 'Em andamento', color: Colors.amber),
  // aliases in pt-BR
  'pendente': OrderStatusInfo(english: 'pending', portuguese: 'Pendente', color: Colors.orange),
  'processando': OrderStatusInfo(english: 'processing', portuguese: 'Processando', color: Colors.blue),
  'aprovado': OrderStatusInfo(english: 'approved', portuguese: 'Aprovado', color: Colors.teal),
  'concluido': OrderStatusInfo(english: 'completed', portuguese: 'Concluído', color: Colors.green),
  'cancelado': OrderStatusInfo(english: 'cancelled', portuguese: 'Cancelado', color: Colors.red),
  'em andamento': OrderStatusInfo(english: 'in_progress', portuguese: 'Em andamento', color: Colors.amber),
};

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  int _selectedIndex = 0;
  String _selectedStatusFilter = 'in_progress'; // Começa em 'Em andamento'
  final TextEditingController _searchController = TextEditingController();
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

 

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredOrders = _allOrders.where((order) {
      final status = order.status.toLowerCase();
      final info = kOrderStatusMap[status];
      bool matchesStatus = true;
      if (_selectedStatusFilter != 'all') {
        switch (_selectedStatusFilter) {
          case 'pending':
            matchesStatus = info?.english == 'pending';
            break;
          case 'in_progress':
            matchesStatus = info?.english == 'processing' || info?.english == 'in_progress';
            break;
          case 'completed':
            matchesStatus = info?.english == 'completed';
            break;
          case 'canceled':
            matchesStatus = info?.english == 'canceled' || info?.english == 'cancelled';
            break;
          case 'approved':
            matchesStatus = info?.english == 'approved';
            break;
          default:
            matchesStatus = true;
        }
      }
      final matchesSearch = _searchQuery.isEmpty ||
          order.id.toString().contains(_searchQuery) ||
          (info?.portuguese.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          order.status.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final api = OrderApiDataSource();
      final orders = await api.getOrders();
      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar pedidos: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().split(".")[0].replaceFirst("T", " ");
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    return kOrderStatusMap[statusLower]?.color ?? Colors.grey;
  }

  String _getStatusText(String status) {
    final statusLower = status.toLowerCase();
    return kOrderStatusMap[statusLower]?.portuguese ?? status;
  }

  Widget _buildStatusFilterChip(String label, String value, Color color) {
    final bool selected = _selectedStatusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/order_form');
          if (result == true) _fetchOrders();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Pedido', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.infoLight,
      ),
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
        title: 'Gestão de Pedidos',
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Primeira linha: Campo de busca e contador
                  Row(
                    children: [
                      // Ícone de filtro
                      Icon(
                        Icons.filter_list,
                        color: AppColors.infoLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      
                      // Campo de pesquisa
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _searchQuery.isNotEmpty 
                                  ? AppColors.infoLight.withValues(alpha: 0.3)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Pesquisar por ID ou status',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => _searchController.clear(),
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.grey[400],
                                        size: 16,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Botão refresh
                      GestureDetector(
                        onTap: _fetchOrders,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.infoLight,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Contador de resultados
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.infoLight,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_filteredOrders.length}',
                              style: TextStyle(
                                color: AppColors.infoLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Segunda linha: Filtros de status
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Pendente', 'pending', Colors.amber),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Em andamento', 'in_progress', Colors.orange),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Aprovados', 'approved', Colors.teal),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Concluídos', 'completed', Colors.green),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Cancelados', 'canceled', Colors.red),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip('Todos', 'all', Colors.grey),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.clear_all,
                                color: Colors.red[600],
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),


// Método correto dentro da classe
                ],
              ),
            ),

            // Lista de pedidos
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchOrders,
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Carregando pedidos...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(32),
                              padding: const EdgeInsets.all(32),
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
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Nenhum pedido encontrado',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente ajustar os filtros ou criar um novo pedido.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              // Log para depuração do status
                              // ignore: avoid_print
                              print('Order #order.id status: order.status');
                              final statusColor = _getStatusColor(order.status);
                              final statusText = _getStatusText(order.status);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey[50]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        await Navigator.pushNamed(context, '/order_detail', arguments: order.id);
                                        _fetchOrders();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            // Ícone do pedido com container estilizado
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: (() {
                                                  final eng = kOrderStatusMap[order.status.toLowerCase()]?.english;
                                                  if (eng == 'processing') {
                                                    return LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Colors.orange.shade400,
                                                        Colors.orange.shade700,
                                                      ],
                                                    );
                                                  } else if (eng == 'pending') {
                                                    return LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Colors.amber.shade300,
                                                        Colors.amber.shade600,
                                                      ],
                                                    );
                                                  } else {
                                                    return LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        statusColor.withValues(alpha: 0.8),
                                                        statusColor,
                                                      ],
                                                    );
                                                  }
                                                })(),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (kOrderStatusMap[order.status.toLowerCase()]?.english == 'processing'
                                                        ? Colors.orange.withOpacity(0.3)
                                                        : statusColor.withValues(alpha: 0.3)),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.receipt_long,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Informações do pedido
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Número do pedido (preferir orderNumber, fallback para id)
                                                  Text(
                                                    (order.orderNumber != null && order.orderNumber!.isNotEmpty)
                                                        ? 'Pedido ${order.orderNumber}'
                                                        : 'Pedido #${order.id}',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Status
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: (() {
                                                        final eng = kOrderStatusMap[order.status.toLowerCase()]?.english;
                                                        if (eng == 'processing') {
                                                          return Colors.orange.withOpacity(0.15);
                                                        } else if (eng == 'pending') {
                                                          return Colors.amber.withOpacity(0.18);
                                                        } else {
                                                          return statusColor.withValues(alpha: 0.1);
                                                        }
                                                      })(),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: (() {
                                                          final eng = kOrderStatusMap[order.status.toLowerCase()]?.english;
                                                          if (eng == 'processing') {
                                                            return Colors.orange.shade700;
                                                          } else if (eng == 'pending') {
                                                            return Colors.amber.shade800;
                                                          } else {
                                                            return statusColor;
                                                          }
                                                        })(),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Data de retirada
                                                  const SizedBox(height: 4),
                                                  // Data de criação
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.add_circle_outline,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Criado: ${_formatDateTime(order.createdAt)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // QR Code e seta
                                            Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: (() {
                                                      final eng = kOrderStatusMap[order.status.toLowerCase()]?.english;
                                                      if (eng == 'processing') {
                                                        return Colors.orange.withOpacity(0.15);
                                                      } else if (eng == 'pending') {
                                                        return Colors.amber.withOpacity(0.18);
                                                      } else {
                                                        return AppColors.infoLight.withValues(alpha: 0.1);
                                                      }
                                                    })(),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.qr_code_2,
                                                    color: (() {
                                                      final eng = kOrderStatusMap[order.status.toLowerCase()]?.english;
                                                      if (eng == 'processing') {
                                                        return Colors.orange.shade700;
                                                      } else if (eng == 'pending') {
                                                        return Colors.amber.shade800;
                                                      } else {
                                                        return AppColors.infoLight;
                                                      }
                                                    })(),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
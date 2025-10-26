import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../components/navBar.dart';
import '../components/standartScreen.dart';
import '../../data/api/purchase_order_api_data_source.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderListPage extends StatefulWidget {
  const PurchaseOrderListPage({super.key});

  @override
  State<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends State<PurchaseOrderListPage> {
  final PurchaseOrderApiDataSource _api = PurchaseOrderApiDataSource();
  List<PurchaseOrder> _orders = [];
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getPurchaseOrders();
      setState(() {
        _orders = list;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar Ordens de Compra: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _displayTitle(PurchaseOrder po) {
    if (po.orderNumber != null && po.orderNumber!.isNotEmpty) return 'NE ${po.orderNumber}';
    return 'NE #${po.id}';
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('delivery') || s.contains('entreg') || s.contains('delivered')) return Colors.green;
    if (s.contains('late') || s.contains('atras')) return Colors.red;
    if (s.contains('pending') || s.contains('pend')) return Colors.orange;
    return Colors.grey;
  }

  String _statusText(String status) {
    if (status.isEmpty) return '—';
    // returns readable label
    final s = status.toLowerCase();
    if (s == 'delivery' || s == 'delivered') return 'Entregue';
    if (s == 'pending_delivery' || s == 'pending') return 'Pendente';
    if (s == 'late') return 'Atrasada';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelada';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomNavbar(currentIndex: _selectedIndex, onTap: (i){ setState(()=> _selectedIndex = i); }),
      body: StandardScreen(
        title: 'Ordens de Compra',
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Lista de Ordens cadastradas', style: TextStyle(fontSize: 16, color: Colors.grey[700]))),
                  IconButton(onPressed: _fetch, icon: Icon(Icons.refresh, color: AppColors.infoLight)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: _orders.isEmpty
                          ? ListView(children: [Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhuma Ordem de Compra encontrada.')))])
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final po = _orders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      onTap: () async {
                                        await Navigator.pushNamed(context, '/purchase_order_detail', arguments: po.id);
                                        _fetch();
                                      },
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _statusColor(po.status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.receipt_long, color: _statusColor(po.status)),
                                      ),
                                      title: Text(_displayTitle(po), style: TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(po.supplierCompanyTitle ?? 'Fornecedor: —'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusColor(po.status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(_statusText(po.status), style: TextStyle(color: _statusColor(po.status), fontWeight: FontWeight.w600)),
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

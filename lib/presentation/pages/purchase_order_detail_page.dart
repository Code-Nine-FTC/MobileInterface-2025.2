import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../components/standartScreen.dart';
import '../components/navBar.dart';
import '../../data/api/purchase_order_api_data_source.dart';
import '../../domain/entities/purchase_order.dart';
import '../../core/utils/secure_storage_service.dart';

class PurchaseOrderDetailPage extends StatefulWidget {
  final int orderId;
  const PurchaseOrderDetailPage({super.key, required this.orderId});

  @override
  State<PurchaseOrderDetailPage> createState() => _PurchaseOrderDetailPageState();
}

class _PurchaseOrderDetailPageState extends State<PurchaseOrderDetailPage> {
  final PurchaseOrderApiDataSource _api = PurchaseOrderApiDataSource();
  PurchaseOrder? _po;
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserAndDetails();
  }

  Future<void> _loadUserAndDetails() async {
    final storage = SecureStorageService();
    final user = await storage.getUser();
    setState(() {
      _userRole = user?.role;
    });
    await _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final po = await _api.getPurchaseOrderById(widget.orderId);
      if (po == null) throw Exception('Ordem não encontrada');
      setState(() { _po = po; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _markDelivered() async {
    if (_po == null) return;
    try {
      final ok = await _api.updateStatus(_po!.id, 'DELIVERY');
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordem marcada como entregue.')));
        await _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao atualizar status.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(currentIndex: _selectedIndex, onTap: (i) { setState(() => _selectedIndex = i); }),
      body: StandardScreen(
        title: _po != null ? 'OC #${_po!.id}' : 'Detalhes da Ordem',
        child: _isLoading ? const Center(child: CircularProgressIndicator()) : _error != null ? _buildError() : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Erro ao carregar: $_error'),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _loadDetails, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'))
        ],
      ),
    );
  }

  Widget _buildContent() {
    final po = _po!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações básicas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Número da Ordem de Compra (OC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('#${po.id}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.infoLight)),
                  ),
                  if (po.commitmentNoteNumber != null) ListTile(title: const Text('Nota de Empenho (NE)'), subtitle: Text(po.commitmentNoteNumber!)),
                  if (po.issuingBody != null) ListTile(title: const Text('Órgão Emissor'), subtitle: Text(po.issuingBody!)),
                  if (po.processNumber != null) ListTile(title: const Text('Número do Processo'), subtitle: Text(po.processNumber!)),
                  ListTile(title: const Text('Fornecedor'), subtitle: Text(po.supplierCompanyTitle ?? '—')),
                  ListTile(title: const Text('Valor total'), subtitle: Text(po.totalValue != null ? 'R\$ ${po.totalValue!.toStringAsFixed(2)}' : '—')),
                  ListTile(title: const Text('Data de emissão'), subtitle: Text(_formatDate(po.issueDate))),
                  ListTile(title: const Text('Status'), subtitle: Text(po.status)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Metadados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(title: const Text('Id'), subtitle: Text(po.id.toString())),
                if (po.year != null) ListTile(title: const Text('Ano'), subtitle: Text(po.year.toString())),
                if (po.orderId != null) ListTile(title: const Text('Pedido associado'), subtitle: Text(po.orderId.toString())),
                if (po.senderName != null) ListTile(title: const Text('Remetente'), subtitle: Text(po.senderName!)),
                if (po.emailStatus != null) ListTile(title: const Text('Status do e-mail'), subtitle: Text(po.emailStatus!)),
                if (po.createdAt != null) ListTile(title: const Text('Criado em'), subtitle: Text(_formatDate(po.createdAt))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          if ((_userRole == 'ADMIN' || _userRole == 'MANAGER') && po.status.toLowerCase() != 'delivery')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _markDelivered,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como Entregue'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../domain/entities/order.dart';
import '../../../data/api/order_api_data_source.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/supplier_api_data_source.dart';
import '../../components/standartScreen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/secure_storage_service.dart';

class OrderFormPage extends StatefulWidget {
  final Order? order;
  const OrderFormPage({super.key, this.order});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SecureStorageService _storageService = SecureStorageService();
  
  late TextEditingController _statusController;
  DateTime? _selectedWithdrawDay;
  List<Map<String, dynamic>> _availableItems = [];
  List<Map<String, dynamic>> _availableSuppliers = [];
  List<int> _selectedItemIds = [];
  List<int> _selectedSupplierIds = [];
  bool _loading = false;
  bool _loadingData = false;
  String? _userRole;

  final List<String> _statusOptions = [
    'pendente',
  ];

  @override
  void initState() {
    super.initState();
    _statusController = TextEditingController(text: widget.order?.status ?? 'pendente');
    _selectedWithdrawDay = widget.order?.withdrawDay ?? DateTime.now().add(const Duration(days: 1));
    _loadInitialData();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingData = true);
    try {
      final user = await _storageService.getUser();
      _userRole = user?.role;
      final sectionId = user?.sessionId;
      
      final itemApi = ItemApiDataSource();
      final supplierApi = SupplierApiDataSource();
      
      // Carregar itens baseado no role do usuário
      String? effectiveSectionId;
      if (_userRole == 'ADMIN') {
        effectiveSectionId = null; // ADMIN vê todos os itens
      } else {
        effectiveSectionId = sectionId;
      }
      
      final items = await itemApi.getItems(sectionId: effectiveSectionId, userRole: _userRole);
      final suppliers = await supplierApi.getSuppliers();
      
      setState(() {
        _availableItems = items;
        _availableSuppliers = suppliers;
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedWithdrawDay ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.infoLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedWithdrawDay ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.infoLight,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedWithdrawDay = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showItemSelectionDialog() {
    showDialog(
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
                        Icon(Icons.inventory_2, color: AppColors.infoLight, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Selecionar Itens',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                        itemCount: _availableItems.length,
                        itemBuilder: (context, index) {
                          final item = _availableItems[index];
                          final dynamic rawId = item['itemId'] ?? item['id'];
                          final int? itemId = rawId is int
                              ? rawId
                              : (rawId is String ? int.tryParse(rawId) : null);
                          if (itemId == null) {

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Text('ID inválido: ' + item.toString()),
                            );
                          }
                          final isSelected = _selectedItemIds.contains(itemId);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.infoLight.withValues(alpha: 0.1) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.infoLight : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    _selectedItemIds.add(itemId);
                                    // Se o item tiver fornecedor, adiciona na lista de fornecedores
                                    final supplierId = item['supplierId'] ?? item['supplier_id'] ?? item['supplier']?['id'];
                                    if (supplierId != null) {
                                      final int? parsedSupplierId = supplierId is int ? supplierId : int.tryParse(supplierId.toString());
                                      if (parsedSupplierId != null && !_selectedSupplierIds.contains(parsedSupplierId)) {
                                        _selectedSupplierIds.add(parsedSupplierId);
                                      }
                                    }
                                  } else {
                                    _selectedItemIds.remove(itemId);
                                  }
                                });
                                setState(() {});
                              },
                              activeColor: AppColors.infoLight,
                              title: Text(
                                item['name']?.toString() ?? 'Item sem nome',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'Estoque: ${item['currentStock'] ?? 0} | ${item['measure'] ?? 'UN'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
                                _selectedItemIds.clear();
                              });
                              setState(() {});
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
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.infoLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Confirmar (${_selectedItemIds.length})'),
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
  }

  void _showSupplierSelectionDialog() {
    showDialog(
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
                        Icon(Icons.business, color: AppColors.infoLight, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Selecionar Fornecedores',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                        itemCount: _availableSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _availableSuppliers[index];
                          final supplierId = supplier['id'] as int;
                          final isSelected = _selectedSupplierIds.contains(supplierId);
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.infoLight.withValues(alpha: 0.1) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.infoLight : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    _selectedSupplierIds.add(supplierId);
                                  } else {
                                    _selectedSupplierIds.remove(supplierId);
                                  }
                                });
                                setState(() {});
                              },
                              activeColor: AppColors.infoLight,
                              title: Text(
                                supplier['name']?.toString() ?? 'Fornecedor sem nome',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: supplier['email'] != null 
                                  ? Text(
                                      supplier['email'].toString(),
                                      style: TextStyle(color: Colors.grey[600]),
                                    )
                                  : null,
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
                                _selectedSupplierIds.clear();
                              });
                              setState(() {});
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
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.infoLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Confirmar (${_selectedSupplierIds.length})'),
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
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pendente': return 'PENDENTE';
      default: return status;
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedWithdrawDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data de retirada')),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um item')),
      );
      return;
    }

    setState(() => _loading = true);
    final api = OrderApiDataSource();
    try {
      if (widget.order == null) {
        await api.createOrder(
          withdrawDay: _selectedWithdrawDay!,
          itemIds: _selectedItemIds.map((id) => id.toInt()).toList(),
          supplierIds: _selectedSupplierIds.map((id) => id.toInt()).toList(),
          status: _statusController.text,
        );
      } else {
        await api.updateOrderStatus(
          orderId: widget.order!.id,
          status: _statusController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.order == null ? 'Pedido criado com sucesso!' : 'Pedido atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar pedido: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: widget.order == null ? 'Novo Pedido' : 'Editar Pedido',
      child: _loadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Status
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.infoLight.withValues(alpha: 0.8), AppColors.infoLight],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Informações Gerais',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _statusController.text,
                            decoration: InputDecoration(
                              labelText: 'Status do Pedido',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: Icon(Icons.flag_outlined, color: AppColors.infoLight),
                            ),
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(_getStatusDisplayName(status)),
                              );
                            }).toList(),
                            onChanged: (value) => _statusController.text = value ?? 'pendente',
                            validator: (v) => v == null || v.isEmpty ? 'Selecione o status' : null,
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _selectDateTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: AppColors.infoLight),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Data de Retirada',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedWithdrawDay != null
                                              ? '${_selectedWithdrawDay!.day.toString().padLeft(2, '0')}/${_selectedWithdrawDay!.month.toString().padLeft(2, '0')}/${_selectedWithdrawDay!.year} às ${_selectedWithdrawDay!.hour.toString().padLeft(2, '0')}:${_selectedWithdrawDay!.minute.toString().padLeft(2, '0')}'
                                              : 'Selecione a data e hora',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _selectedWithdrawDay != null ? Colors.black87 : Colors.grey[500],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card Itens
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange.withOpacity(0.8), Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Itens do Pedido (${_selectedItemIds.length})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedItemIds.isNotEmpty ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedItemIds.isNotEmpty ? 'Selecionados' : 'Obrigatório',
                                  style: TextStyle(
                                    color: _selectedItemIds.isNotEmpty ? Colors.green[700] : Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showItemSelectionDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.infoLight.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.infoLight.withOpacity(0.05),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_shopping_cart, color: AppColors.infoLight),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Selecionar Itens',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: AppColors.infoLight, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_selectedItemIds.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Itens Selecionados:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedItemIds.map((itemId) {
                                final item = _availableItems.firstWhere(
                                  (item) => item['id'] == itemId,
                                  orElse: () => {'name': 'Item #$itemId'},
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.infoLight.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    item['name']?.toString() ?? 'Item #$itemId',
                                    style: TextStyle(
                                      color: AppColors.infoLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple.withOpacity(0.8), Colors.purple],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.business, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Fornecedores (${_selectedSupplierIds.length})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Selecione',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showSupplierSelectionDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.purple.withOpacity(0.05),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.business_center, color: Colors.purple),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Selecionar Fornecedores',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_selectedSupplierIds.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Fornecedores Selecionados:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSupplierIds.map((supplierId) {
                                final supplier = _availableSuppliers.firstWhere(
                                  (supplier) => supplier['id'] == supplierId,
                                  orElse: () => {'name': 'Fornecedor #$supplierId'},
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    supplier['name']?.toString() ?? 'Fornecedor #$supplierId',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.infoLight,
                            AppColors.infoLight.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.infoLight.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: _loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_rounded, color: Colors.white, size: 24),
                          label: Text(
                            _loading 
                                ? 'Salvando...' 
                                : widget.order == null 
                                    ? 'Criar Pedido' 
                                    : 'Atualizar Pedido',
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _loading ? null : _saveOrder,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }}
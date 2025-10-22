import 'package:flutter/material.dart';
import '../../../domain/entities/order.dart';
import '../../../data/api/order_api_data_source.dart';
import '../../../data/api/section_api_data_source.dart';
import '../../../data/api/item_api_data_source.dart';
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
  final TextEditingController _orderNumberController = TextEditingController();
  void _onSavePressed() {
    _saveOrder();
  }
  Future<void> _initSelectedItemsAndLoadData() async {
    if (widget.order != null) {
      final api = OrderApiDataSource();
      final orderItems = await api.getOrderItemsByOrderId(widget.order!.id);
      setState(() {
        _selectedItemQuantities = {
          for (final item in orderItems) item.id: item.quantity
        };
      });
    }
    await _loadInitialData();
  }
  final _formKey = GlobalKey<FormState>();
  final SecureStorageService _storageService = SecureStorageService();
  List<Map<String, dynamic>> _availableItems = [];
  List<Map<String, dynamic>> _consumerSections = [];
  int? _selectedConsumerSectionId;
  // Removido: fornecedores
  Map<int, int> _selectedItemQuantities = {}; // itemId -> quantidade
  // Removido: seleção de fornecedores
  bool _loading = false;
  bool _loadingData = false;
  String? _userRole;

  // final List<String> _statusOptions = [
  //   'pendente',
  // ];

  @override
  void initState() {
    super.initState();
    _initSelectedItemsAndLoadData();
  }

  @override
  void dispose() {
  _orderNumberController.dispose();
  // _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingData = true);
    try {
      final user = await _storageService.getUser();
      _userRole = user?.role;
      final sectionId = user?.sessionId;
      
      final itemApi = ItemApiDataSource();
      final sectionApi = SectionApiDataSource();
      
      // Carregar itens baseado no role do usuário
      String? effectiveSectionId;
      if (_userRole == 'ADMIN') {
        effectiveSectionId = null; // ADMIN vê todos os itens
      } else {
        effectiveSectionId = sectionId;
      }
      
      final items = await itemApi.getItems(sectionId: effectiveSectionId, userRole: _userRole);
      final sections = await sectionApi.getConsumerSections();
      setState(() {
        _availableItems = items;
        _consumerSections = sections;
        // Se não conseguimos listar seções, usar seção do usuário como default (se existir)
        if (_consumerSections.isEmpty && sectionId != null) {
          _selectedConsumerSectionId = int.tryParse(sectionId);
        }
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
      if (mounted) {
        final msg = e.toString().contains('403')
            ? 'Sem permissão para listar seções (403). Usando sua seção padrão se disponível.'
            : 'Erro ao carregar dados: $e';
        // Tentar usar seção do usuário como fallback
        final user = await _storageService.getUser();
        final sectionId = user?.sessionId;
        if (_selectedConsumerSectionId == null && sectionId != null) {
          setState(() {
            _selectedConsumerSectionId = int.tryParse(sectionId);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _reloadSections() async {
    try {
      final sectionApi = SectionApiDataSource();
      final sections = await sectionApi.getConsumerSections();
      setState(() {
        _consumerSections = sections;
      });
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('403')
            ? 'Sem permissão para listar seções (403).'
            : 'Erro ao carregar seções: $e';
        // fallback: manter valor atual se houver
        if (_selectedConsumerSectionId == null) {
          final user = await _storageService.getUser();
          final sectionId = user?.sessionId;
          if (sectionId != null) {
            setState(() {
              _selectedConsumerSectionId = int.tryParse(sectionId);
            });
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }



  void _showItemSelectionDialog() {
    // Cópia local do mapa de itens selecionados
  Map<int, int> localSelected = Map<int, int>.from(_selectedItemQuantities);
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
                          final isSelected = localSelected.containsKey(itemId);
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
                              onChanged: (bool? value) async {
                                if (value == true) {
                                  final qty = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      int tempQty = 1;
                                      return AlertDialog(
                                        title: Text('Quantidade para ${item['name'] ?? 'Item'}'),
                                        content: TextFormField(
                                          initialValue: '1',
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
                                            child: const Text('Adicionar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (qty != null && qty > 0) {
                                    setDialogState(() {
                                      localSelected[itemId] = qty;
                                    });
                                    setState(() {});
                                  }
                                } else {
                                  setDialogState(() {
                                    localSelected.remove(itemId);
                                  });
                                  setState(() {});
                                }
                              },
                              activeColor: AppColors.infoLight,
                              title: Text(
                                '${item['name']?.toString() ?? 'Item sem nome'}${isSelected ? '  x${localSelected[itemId]}' : ''}',
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
                                localSelected.clear();
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
                            onPressed: () {
                              setState(() {
                                _selectedItemQuantities = Map<int, int>.from(localSelected);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.infoLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Confirmar (${localSelected.length})'),
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

  // Removido: diálogo de seleção de fornecedores



  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um item')),
      );
      return;
    }
    // consumerSectionId obrigatório na criação
    if (widget.order == null && _selectedConsumerSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a Seção Consumidora')),
      );
      return;
    }
    setState(() => _loading = true);
    final api = OrderApiDataSource();
    try {
      Map<String, int> itemQuantities = {};
      _selectedItemQuantities.forEach((itemId, qty) {
        itemQuantities[itemId.toString()] = qty;
      });
      if (widget.order == null) {
        await api.createOrder(
          itemQuantities: itemQuantities,
          orderNumber: _orderNumberController.text.trim(),
          consumerSectionId: _selectedConsumerSectionId!,
        );
      } else {
        await api.updateOrderItems(
          widget.order!.id,
          _selectedItemQuantities,
          widget.order!.withdrawDay,
          consumerSectionId: _selectedConsumerSectionId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.order == null ? 'Pedido criado com sucesso!' : 'Pedido atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/order_management');
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
                    // Número manual do pedido (opcional)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
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
                                child: Icon(Icons.tag, color: AppColors.infoLight, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text('Número do Pedido', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _orderNumberController,
                            decoration: const InputDecoration(
                              hintText: 'Ex.: 2025-000123',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              isDense: true,
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o número do pedido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Text('Campo obrigatório', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                        ],
                      ),
                    ),
                    // Seção Consumidora (obrigatória na criação)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
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
                                child: Icon(Icons.apartment, color: AppColors.infoLight, size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text('Seção Consumidora', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_consumerSections.isNotEmpty)
                            DropdownButtonFormField<int>(
                              value: _selectedConsumerSectionId,
                              items: _consumerSections
                                  .map((s) => DropdownMenuItem<int>(
                                        value: s['id'] as int?,
                                        child: Text(s['title']?.toString() ?? 'Seção'),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedConsumerSectionId = v),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                isDense: true,
                                prefixIcon: Icon(Icons.store_mall_directory_outlined),
                              ),
                              validator: (v) {
                                if (widget.order == null && (v == null)) {
                                  return 'Selecione a Seção Consumidora';
                                }
                                return null;
                              },
                            )
                          else if (_selectedConsumerSectionId != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                'Seção selecionada: ID ${_selectedConsumerSectionId} (padrão) — não foi possível listar seções.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          if (_consumerSections.isEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Nenhuma seção consumidora encontrada. Verifique sua conexão/servidor e tente recarregar.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _reloadSections,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Recarregar'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          if (widget.order == null)
                            Text('Campo obrigatório', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                        ],
                      ),
                    ),
                    // ... Removido card de status e data de retirada ...

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
                                  'Itens do Pedido (${_selectedItemQuantities.length})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedItemQuantities.isNotEmpty ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _selectedItemQuantities.isNotEmpty ? 'Selecionados' : 'Obrigatório',
                                  style: TextStyle(
                                    color: _selectedItemQuantities.isNotEmpty ? Colors.green[700] : Colors.red[700],
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
                          if (_selectedItemQuantities.isNotEmpty) ...[
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
                              children: _selectedItemQuantities.entries.map((entry) {
                                final item = _availableItems.firstWhere(
                                  (item) => (item['id'] ?? item['itemId']) == entry.key,
                                  orElse: () => {'name': 'Item #${entry.key}'},
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.infoLight.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${item['name']?.toString() ?? 'Item #${entry.key}'}  x${entry.value}',
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
                          ),
                          onPressed: _loading ? null : _onSavePressed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
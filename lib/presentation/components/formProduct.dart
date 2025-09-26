import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/supplier_api_data_source.dart';
import '../../data/api/item_type_api_data_source.dart';
 import '../../../core/utils/secure_storage_service.dart';

class ProductForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function()? onSubmit;
  final List<String> requiredFields;

  final void Function(Map<String, dynamic> values)? onChanged;

  const ProductForm({
    super.key,
    required this.formKey,
    this.onSubmit,
    this.requiredFields = const [],
    this.onChanged,
  });

  @override
  State<ProductForm> createState() => ProductFormState();
}


class ProductFormState extends State<ProductForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  String? _measure;
  final TextEditingController _expireDateController = TextEditingController();
  String? _supplierId;
  String? _itemTypeId;
  final TextEditingController _minimumStockController = TextEditingController();
  final TextEditingController _maximumStockController = TextEditingController();

  final SecureStorageService _storageService = SecureStorageService();
  bool _isActive = true; 
  bool _hasExpiryDate = false; 

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _itemTypes = [];
  bool _isLoadingData = true;
  String? _loadError;

  final SupplierApiDataSource _supplierApi = SupplierApiDataSource();
  final ItemTypeApiDataSource _itemTypeApi = ItemTypeApiDataSource();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final user = await _storageService.getUser();
      final userRole = user?.role ?? '';
      final sectionId = user?.sessionId;

      print('[FormProduct] Carregando dados do dropdown para role: $userRole');

      final futures = await Future.wait([
        _supplierApi.getSuppliers(
          sectionId: sectionId != null ? int.tryParse(sectionId) : null,
          userRole: userRole,
        ),
        _itemTypeApi.getItemTypes(
          sectionId: sectionId != null ? int.tryParse(sectionId) : null,
        ),
      ]);

      setState(() {
        _suppliers = futures[0];
        _itemTypes = futures[1];
        _isLoadingData = false;

        if (_supplierId != null && !_suppliers.any((s) => s['id'].toString() == _supplierId)) {
          _supplierId = null;
        }
        if (_itemTypeId != null && !_itemTypes.any((t) => t['id'].toString() == _itemTypeId)) {
          _itemTypeId = null;
        }
      });

      print('[FormProduct] Carregados ${_suppliers.length} fornecedores e ${_itemTypes.length} tipos de item');
    } catch (e) {
      print('[FormProduct] Erro ao carregar dados: $e');
      setState(() {
        _isLoadingData = false;
        _loadError = 'Erro ao carregar dados: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: AppColors.errorLight,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isLoadingData = true;
                  _loadError = null;
                });
                _loadDropdownData();
              },
            ),
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar fornecedores e tipos de item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<TextInputFormatter> get dateInputFormatter => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
    DateInputFormatter(),
  ];

  void _notifyChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(getFormValues());
    }
  }
  String? _convertDateToIso(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        final dateTime = DateTime(year, month, day);
        return dateTime.toIso8601String();
      }
    } catch (e) {
      print('[FormProduct] Erro ao converter data: $e');
    }
    
    return null;
  }


  Map<String, dynamic> getFormValues() {
    final formData = {
      "name": _nameController.text,
      "currentStock": int.tryParse(_currentStockController.text) ?? 0,
      "measure": _measure,
      "expireDate": _hasExpiryDate ? _convertDateToIso(_expireDateController.text) : null,
      "supplierId": _supplierId != null ? int.tryParse(_supplierId!) : null,
      "itemTypeId": _itemTypeId != null ? int.tryParse(_itemTypeId!) : null,
      "minimumStock": int.tryParse(_minimumStockController.text) ?? 0,
      "maximumStock": int.tryParse(_maximumStockController.text) ?? 0,
      "isActive": _isActive,
    };
    return formData;
  }

  Widget _buildInput(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<String>? options,
    bool enabled = true,
    TextEditingController? controller,
    String? dropdownValue,
    void Function(String?)? onDropdownChanged,
    IconData? prefixIcon,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (options != null && options.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText ?? "Selecione $label",
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryLight) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: TextStyle(color: Colors.grey.shade600),
          ),
          items: options
              .map((e) => DropdownMenuItem(
                value: e, 
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                )
              ))
              .toList(),
          value: dropdownValue,
          onChanged: enabled
              ? (value) {
                  if (onDropdownChanged != null) onDropdownChanged(value);
                  _notifyChange();
                }
              : null,
          validator: (value) {
            if (widget.requiredFields.contains(label) &&
                (value == null || value.isEmpty)) {
              return "Selecione o campo $label";
            }
            return null;
          },
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(fontSize: 16),
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText ?? "Digite $label",
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryLight) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: TextStyle(color: enabled ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
          onChanged: (_) => _notifyChange(),
          validator: (value) {
            if (widget.requiredFields.contains(label) &&
                (value == null || value.isEmpty)) {
              return "Preencha o campo $label";
            }
            if (label.contains("Estoque") && value != null && value.isNotEmpty) {
              final number = int.tryParse(value);
              if (number == null || number < 0) {
                return "Digite um número válido";
              }
            }
            return null;
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Carregando fornecedores e tipos...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Tentar novamente"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(color: AppColors.primaryLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoadingData = true;
                      _loadError = null;
                    });
                    _loadDropdownData();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.primaryLight,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cadastro de Produto',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha os dados do novo produto',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSectionHeader('Informações Básicas', Icons.info_outline_rounded),
              _buildInput(
                "Nome",
                controller: _nameController,
                prefixIcon: Icons.label_outline_rounded,
                hintText: "Nome do produto",
              ),
              _buildInput(
                "Tipo do Item",
                options: _isLoadingData 
                  ? ["Carregando tipos..."]
                  : _itemTypes.isEmpty 
                    ? ["Nenhum tipo encontrado"]
                    : _itemTypes.map((type) => "${type['id']} - ${type['name']}").toList(),
                dropdownValue: _itemTypeId != null && _itemTypes.isNotEmpty
                  ? _itemTypes
                      .where((type) => type['id'].toString() == _itemTypeId)
                      .map((type) => "${type['id']} - ${type['name']}")
                      .firstOrNull
                  : null,
                prefixIcon: Icons.category_outlined,
                enabled: !_isLoadingData && _itemTypes.isNotEmpty,
                onDropdownChanged: (_isLoadingData || _itemTypes.isEmpty) ? null : (val) { 
                  setState(() { 
                    _itemTypeId = val?.split(' - ')[0];
                  }); 
                  _notifyChange(); 
                },
              ),

              _buildSectionHeader('Controle de Estoque', Icons.inventory_outlined),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInput(
                      "Estoque Atual",
                      keyboardType: TextInputType.number,
                      controller: _currentStockController,
                      prefixIcon: Icons.numbers_rounded,
                      hintText: "Quantidade atual",
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildInput(
                      "Unidade",
                      options: ["kg", "g", "l", "ml", "unidade"],
                      dropdownValue: _measure,
                      prefixIcon: Icons.straighten_rounded,
                      onDropdownChanged: (val) { setState(() { _measure = val; }); _notifyChange(); },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      "Min. Stock",
                      keyboardType: TextInputType.number,
                      controller: _minimumStockController,
                      prefixIcon: Icons.warning_amber_rounded,
                      hintText: "Mínimo",
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      "Max. Stock",
                      keyboardType: TextInputType.number,
                      controller: _maximumStockController,
                      prefixIcon: Icons.trending_up_rounded,
                      hintText: "Máximo",
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              _buildSectionHeader('Data de Expiração', Icons.schedule_outlined),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: _hasExpiryDate ? AppColors.primaryLight : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Possui data de expiração?",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _hasExpiryDate ? "Data de expiração será definida" : "Produto não expira",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _hasExpiryDate,
                        onChanged: (value) {
                          setState(() {
                            _hasExpiryDate = value;
                            if (!value) {
                              _expireDateController.clear();
                            } else {
                              final now = DateTime.now();
                              _expireDateController.text = 
                                  "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
                            }
                          });
                          _notifyChange();
                        },
                        activeColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasExpiryDate) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInput(
                        "Data de Expiração",
                        keyboardType: TextInputType.number,
                        controller: _expireDateController,
                        prefixIcon: Icons.calendar_today_rounded,
                        hintText: "DD/MM/AAAA",
                        inputFormatters: dateInputFormatter,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                          foregroundColor: AppColors.primaryLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          final now = DateTime.now();
                          _expireDateController.text = 
                              "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
                          _notifyChange();
                        },
                        child: const Icon(Icons.today_rounded),
                      ),
                    ),
                  ],
                ),
              ],
              _buildSectionHeader('Fornecedor', Icons.business_rounded),
              _buildInput(
                "Fornecedor",
                options: _isLoadingData 
                  ? ["Carregando fornecedores..."]
                  : _suppliers.isEmpty 
                    ? ["Nenhum fornecedor encontrado"]
                    : _suppliers.map((supplier) => "${supplier['id']} - ${supplier['name']}").toList(),
                dropdownValue: _supplierId != null && _suppliers.isNotEmpty
                  ? _suppliers
                      .where((supplier) => supplier['id'].toString() == _supplierId)
                      .map((supplier) => "${supplier['id']} - ${supplier['name']}")
                      .firstOrNull
                  : null,
                prefixIcon: Icons.store_rounded,
                enabled: !_isLoadingData && _suppliers.isNotEmpty,
                onDropdownChanged: (_isLoadingData || _suppliers.isEmpty) ? null : (val) { 
                  setState(() { 
                    _supplierId = val?.split(' - ')[0];
                  }); 
                  _notifyChange(); 
                },
              ),

              if (_loadError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Recarregar dados"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isLoadingData = true;
                        _loadError = null;
                      });
                      _loadDropdownData();
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),

              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.onSubmit,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Cadastrar Produto",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
  Map<String, dynamic> get values => getFormValues();
}
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 2) {
      return newValue;
    } else if (text.length <= 4) {
      return newValue.copyWith(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
      );
    } else if (text.length <= 8) {
      return newValue.copyWith(
        text: '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}',
        selection: TextSelection.collapsed(offset: newValue.selection.end + 2),
      );
    }
    
    return oldValue;
  }
}

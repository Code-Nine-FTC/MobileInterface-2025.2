import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';


class ProductForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function()? onSubmit;
  final List<String> requiredFields;

  // Callback to provide form values to parent
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
  // Controllers and state for all fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _unit;
  String? _itemType;
  final TextEditingController _minStockController = TextEditingController();
  bool validadeEnabled = false;
  final TextEditingController _validityController = TextEditingController();
  String? _supplier;
  final TextEditingController _registrationDateController = TextEditingController();

  // Helper to notify parent of value changes
  void _notifyChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(getFormValues());
    }
  }

  Map<String, dynamic> getFormValues() {
    return {
      "name": _nameController.text,
      "quantity": _quantityController.text,
      "unit": _unit,
      "minStock": _minStockController.text,
      "validity": validadeEnabled ? _validityController.text : null,
      "supplier": _supplier,
      "registrationDate": _registrationDateController.text,
      "hasValidity": validadeEnabled,
      "itemType": _itemType,
    };
  }

  Widget _buildInput(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<String>? options,
    bool enabled = true,
    TextEditingController? controller,
    String? dropdownValue,
    void Function(String?)? onDropdownChanged,
  }) {
    if (options != null && options.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => _notifyChange(),
          validator: (value) {
            if (widget.requiredFields.contains(label) &&
                (value == null || value.isEmpty)) {
              return "Preencha o campo $label";
            }
            return null;
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInput("Nome", controller: _nameController),
            _buildInput(
              "Tipo do Item",
              options: ["Alimento", "Bebida", "Limpeza"],
              dropdownValue: _itemType,
              onDropdownChanged: (val) { setState(() { _itemType = val; }); _notifyChange(); },
            ),
            _buildInput("Quantidade", keyboardType: TextInputType.number, controller: _quantityController),
            _buildInput(
              "Unidade de Medida",
              options: ["kg", "g", "l", "ml", "unidade"],
              dropdownValue: _unit,
              onDropdownChanged: (val) { setState(() { _unit = val; }); _notifyChange(); },
            ),
            _buildInput("Estoque mínimo", keyboardType: TextInputType.number, controller: _minStockController),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Possui validade?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: validadeEnabled,
                  onChanged: (value) {
                    setState(() {
                      validadeEnabled = value;
                    });
                    _notifyChange();
                  },
                ),
              ],
            ),
            _buildInput(
              "Validade",
              keyboardType: TextInputType.datetime,
              enabled: validadeEnabled,
              controller: _validityController,
            ),
            _buildInput(
              "Fornecedor",
              options: ["Fornecedor A", "Fornecedor B", "Fornecedor C"],
              dropdownValue: _supplier,
              onDropdownChanged: (val) { setState(() { _supplier = val; }); _notifyChange(); },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Cadastrar novo fornecedor"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.infoLight),
              onPressed: () {
                Navigator.of(context).pushNamed('/supplier_register');
              },
            ),
            const SizedBox(height: 12),
            _buildInput("Data do cadastro", controller: _registrationDateController),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.infoLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onSubmit,
              child: const Text("Cadastrar")
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Expose form values to parent (optional getter)
  Map<String, dynamic> get values => getFormValues();
}

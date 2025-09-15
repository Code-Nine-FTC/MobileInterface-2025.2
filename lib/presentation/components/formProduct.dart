import 'package:flutter/material.dart';


class ProductForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function()? onSubmit;
  final List<String> requiredFields;

  const ProductForm({
    super.key,
    required this.formKey,
    this.onSubmit,
    this.requiredFields = const [],
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  bool validadeEnabled = false;


  Widget _buildInput(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<String>? options,
    bool enabled = true,
  }) {
    if (options != null && options.isNotEmpty) {
      String? selectedValue;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          value: selectedValue,
          onChanged: enabled ? (value) { selectedValue = value; } : null,
          validator: (value) {
            if (widget.requiredFields.contains(label) && (value == null || value.isEmpty)) {
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
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (widget.requiredFields.contains(label) && (value == null || value.isEmpty)) {
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInput("Nome"),
            _buildInput("Quantidade", keyboardType: TextInputType.number),
            _buildInput(
              "Unidade de Medida",
              options: ["kg", "g", "l", "ml", "unidade"],
            ),
            _buildInput("Estoque mínimo", keyboardType: TextInputType.number),
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
                  },
                ),
              ],
            ),
            _buildInput(
              "Validade",
              keyboardType: TextInputType.datetime,
              enabled: validadeEnabled,
            ),
            _buildInput("Fornecedor", options: ["Fornecedor A", "Fornecedor B", "Fornecedor C"]),
            _buildInput("Data do cadastro"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onSubmit,
              child: const Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}

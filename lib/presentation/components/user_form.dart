import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UserForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final void Function()? onSubmit;
  final List<String> requiredFields;

  const UserForm({
    super.key,
    required this.formKey,
    this.onSubmit,
    this.requiredFields = const [],
  });

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  bool isAdmin = false;
  String? selectedSetor;

  Widget _buildInput(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    List<String>? options,
    bool enabled = true,
  }) {
    if (options != null && options.isNotEmpty) {
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
          value: selectedSetor,
          onChanged: enabled
              ? (value) {
                  setState(() {
                    selectedSetor = value;
                  });
                }
              : null,
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
            _buildInput("Email", keyboardType: TextInputType.emailAddress),
            _buildInput("Senha", keyboardType: TextInputType.visiblePassword),
            _buildInput(
              "Setor",
              options: ["Almoxarifado", "Farmácia"],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "É administrador",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Checkbox(
                  value: isAdmin,
                  onChanged: (value) {
                    setState(() {
                      isAdmin = value ?? false;
                    });
                  },
                  activeColor: AppColors.infoLight,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.infoLight,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}

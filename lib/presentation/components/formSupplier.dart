import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../data/api/supplier_api_data_source.dart';

class SupplierFormScreen extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String? supplierId;
  final void Function(Map<String, dynamic>)? onSubmit;

  const SupplierFormScreen({
    super.key,
    required this.formKey,
    this.supplierId,
    this.onSubmit,
  });

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final SupplierApiDataSource _supplierApiDataSource = SupplierApiDataSource();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    if (widget.supplierId != null) {
      _fetchSupplierData(widget.supplierId!);
    }
  }

  Future<void> _fetchSupplierData(String supplierId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supplier = await _supplierApiDataSource.getSupplierById(supplierId);
      setState(() {
        _nameController.text = supplier['name'] ?? '';
        _cnpjController.text = supplier['cnpj'] ?? '';
        _emailController.text = supplier['email'] ?? '';
        _phoneController.text = supplier['phone'] ?? '';
        _urlController.text = supplier['url'] ?? '';
        _isActive = supplier['isActive'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do fornecedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Preencha o campo E-mail';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(value)) {
      return 'Formato de e-mail inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Fantasia',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Preencha o campo Nome Fantasia';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cnpjController,
              decoration: const InputDecoration(
                labelText: 'CNPJ',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_cnpjFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Preencha o campo CNPJ';
                }
                if (!_cnpjFormatter.isFill()) {
                  return 'CNPJ incompleto';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Preencha o campo Telefone';
                }
                if (!_phoneFormatter.isFill()) {
                  return 'Telefone incompleto';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Fornecedor Ativo'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.formKey.currentState?.validate() ?? false) {
                  final supplierData = {
                    'name': _nameController.text.trim(),
                    'cnpj': _cnpjController.text.trim(),
                    'email': _emailController.text.trim(),
                    'phoneNumber': _phoneController.text.trim(),
                    'url': _urlController.text.trim(),
                    'isActive': _isActive,
                    'id': widget.supplierId,
                  };
                  if (widget.onSubmit != null) {
                    widget.onSubmit!(supplierData);
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}

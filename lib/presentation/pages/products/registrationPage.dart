import 'package:flutter/material.dart';
import '../../components/formProduct.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart'; // se CustomNavbar estiver aqui
import '../../../data/api/item_api_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/secure_storage_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
  
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ProductFormState> _productFormKey = GlobalKey<ProductFormState>();
  final SecureStorageService _storageService = SecureStorageService();
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/menu');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/perfil');
        break;
    }
  }

  Future<void> _registerProduct() async {
    if (_formKey.currentState!.validate()) {
      final formState = _productFormKey.currentState;
      if (formState == null) return;
      final values = formState.getFormValues();

      // Validações básicas
      if (values["name"] == null || values["name"].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome do produto é obrigatório')),
        );
        return;
      }

      if (values["currentStock"] == null || values["currentStock"] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estoque atual deve ser maior que zero')),
        );
        return;
      }

      if (values["supplierId"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um fornecedor')),
        );
        return;
      }

      if (values["itemTypeId"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um tipo de item')),
        );
        return;
      }

      try {
        final token = await _storageService.getToken();

        print('[RegistrationPage] Enviando dados para API: $values');
        
        final api = ItemApiDataSource();
        await api.createItem(values);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto registrado com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('[RegistrationPage] Erro ao registrar produto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar produto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Registro de Produto',
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ProductForm(
            key: _productFormKey,
            formKey: _formKey,
            onSubmit: _registerProduct,
            requiredFields: ["Nome", "Estoque mínimo", "Data do cadastro"],
          ),
        ),
      ),
    );
  }
}

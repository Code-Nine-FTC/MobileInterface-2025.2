import 'package:flutter/material.dart';
import '../../components/formProduct.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart'; // se CustomNavbar estiver aqui
import '../../../data/api/item_api_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
  
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ProductFormState> _productFormKey = GlobalKey<ProductFormState>();

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

      // Map frontend fields to backend ItemRequest DTO
      // Mapear fornecedores para IDs (exemplo simples)
      final supplierNameToId = {
        "Fornecedor A": 1,
        "Fornecedor B": 2,
        "Fornecedor C": 3,
      };
      final supplierId = supplierNameToId[values["supplier"]];

      // Mapear tipos de item para IDs (exemplo simples)
      final itemTypeNameToId = {
        "Alimento": 1,
        "Bebida": 2,
        "Limpeza": 3,
      };
      final itemTypeId = itemTypeNameToId[values["itemType"]];

      // Formatar data para yyyy-MM-dd
      String? formattedDate;
      if (values["registrationDate"] != null && values["registrationDate"].toString().trim().isNotEmpty) {
        try {
          final parts = values["registrationDate"].split("/");
          if (parts.length == 3) {
            // Suporta formato dd/MM/yyyy
            formattedDate = "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
          } else {
            formattedDate = values["registrationDate"];
          }
        } catch (_) {
          formattedDate = values["registrationDate"];
        }
      }

      final itemRequest = {
        "name": values["name"],
        "quantity": int.tryParse(values["quantity"] ?? "0"),
        "unit": values["unit"],
        "minStock": int.tryParse(values["minStock"] ?? "0"),
        "validity": values["hasValidity"] ? values["validity"] : null,
        "supplierId": supplierId,
        "itemTypeId": itemTypeId,
        "registrationDate": formattedDate,
      };

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        final api = ItemApiDataSource();
        await api.createItem(itemRequest, token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto registrado com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProductForm(
          key: _productFormKey,
          formKey: _formKey,
          onSubmit: _registerProduct,
          requiredFields: ["Nome", "Estoque mínimo", "Data do cadastro"],
        ),
      ),
    );
  }
}

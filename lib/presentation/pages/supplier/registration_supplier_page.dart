import 'package:flutter/material.dart';
import '../../components/formSupplier.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart';

class RegistrationSupplierPage extends StatefulWidget {
  const RegistrationSupplierPage({super.key});

  @override
  State<RegistrationSupplierPage> createState() =>
      _RegistrationSupplierPageState();
}

class _RegistrationSupplierPageState extends State<RegistrationSupplierPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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

  void _registerSupplier(Map<String, dynamic> supplierData) {
    if (_formKey.currentState!.validate()) {
      // TODO: Lógica para envio de dados para o backend (SupplierService)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fornecedor registrado com sucesso!')),
      );
      // TODO: Redirecionar para lista de fornecedores
      // Navigator.pushReplacementNamed(context, '/suppliers');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Registro de Fornecedor',
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SupplierFormScreen(
          formKey: _formKey,
          onSubmit: _registerSupplier,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../components/formProduct.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart'; // se CustomNavbar estiver aqui

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
  
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedIndex = 0; // índice inicial do Navbar

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

  void _registerProduct() {
    if (_formKey.currentState!.validate()) {
      // Lógica para envio de dados para o backend

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto registrado com sucesso!')),
      );
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
          formKey: _formKey,
          onSubmit: _registerProduct,
          requiredFields: ["Nome", "Estoque mínimo", "Data do cadastro"],
        ),
      ),
    );
  }
}

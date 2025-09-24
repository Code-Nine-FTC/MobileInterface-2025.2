import 'package:flutter/material.dart';
import '../../../data/api/supplier_api_data_source.dart';
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
  final SupplierApiDataSource _supplierApi = SupplierApiDataSource();
  int _selectedIndex = 0;
  int? _supplierId; // Para edição
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verifica se foi passado um ID para edição
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is int) {
      _supplierId = arguments;
    }
  }

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

  Future<void> _saveSupplier(Map<String, dynamic> supplierData) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_supplierId != null) {
        // Edição
        await _supplierApi.updateSupplier(_supplierId.toString(), supplierData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fornecedor atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Criação
        await _supplierApi.createSupplier(supplierData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fornecedor registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Voltar para a lista de fornecedores
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/supplier_management');
      }
      
    } catch (e) {
      print('[RegistrationSupplierPage] Erro ao salvar fornecedor: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao ${_supplierId != null ? 'atualizar' : 'registrar'} fornecedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: _supplierId != null ? 'Editar Fornecedor' : 'Registro de Fornecedor',
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SupplierFormScreen(
              formKey: _formKey,
              supplierId: _supplierId?.toString(),
              onSubmit: _saveSupplier,
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Salvando fornecedor...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

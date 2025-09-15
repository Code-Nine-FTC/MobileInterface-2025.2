import 'package:flutter/material.dart';
import '../components/standartScreen.dart';
import '../components/user_form.dart';

class UserRegisterPage extends StatelessWidget {
  UserRegisterPage({super.key});

  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implementar lógica de cadastro
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Cadastro usuário',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: UserForm(
              formKey: _formKey,
              onSubmit: _submit,
              requiredFields: const ['Nome', 'Email', 'Senha', 'Setor'],
            ),
          ),
        ),
      ),
    );
  }
}

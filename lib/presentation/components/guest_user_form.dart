import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class GuestUserForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cpfController;
  final TextEditingController ageController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? selectedGender;
  final void Function(String?)? onGenderChanged;

  const GuestUserForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.cpfController,
    required this.ageController,
    required this.emailController,
    required this.passwordController,
    this.selectedGender,
    this.onGenderChanged,
  });

  @override
  State<GuestUserForm> createState() => _GuestUserFormState();
}

class _GuestUserFormState extends State<GuestUserForm> {
  bool _obscurePassword = true;

  String? _validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o CPF';
    }
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    // Validação básica de CPF (pode melhorar)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o e-mail';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a idade';
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Idade inválida';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nome
            TextFormField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome completo';
                }
                if (value.trim().length < 3) {
                  return 'Nome deve ter no mínimo 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // CPF
            TextFormField(
              controller: widget.cpfController,
              decoration: InputDecoration(
                labelText: 'CPF',
                hintText: '000.000.000-00',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _CpfInputFormatter(),
              ],
              validator: _validateCPF,
            ),
            const SizedBox(height: 16),

            // Idade e Sexo (lado a lado)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: widget.ageController,
                    decoration: InputDecoration(
                      labelText: 'Idade',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: _validateAge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: widget.selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Sexo',
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                      DropdownMenuItem(value: 'F', child: Text('Feminino')),
                      DropdownMenuItem(value: 'O', child: Text('Outro')),
                    ],
                    onChanged: widget.onGenderChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione o sexo';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // E-mail
            TextFormField(
              controller: widget.emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: 'cliente@exemplo.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),

            // Senha
            TextFormField(
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo 6 caracteres',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscurePassword,
              validator: _validatePassword,
            ),
          ],
        ),
      ),
    );
  }
}

// Formatter para CPF (000.000.000-00)
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

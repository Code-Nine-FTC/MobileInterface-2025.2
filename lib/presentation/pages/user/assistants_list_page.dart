import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/navBar.dart';
import '../../components/standartScreen.dart';

class AssistantsListPage extends StatefulWidget {
  const AssistantsListPage({super.key});

  @override
  State<AssistantsListPage> createState() => _AssistantsListPageState();
}

class _AssistantsListPageState extends State<AssistantsListPage> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/menu');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auxiliares = List.generate(5, (i) => 'Auxiliar ${i + 1}');
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.pushNamed(context, '/user_register');
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Auxiliar', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.infoLight,
      ),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      body: StandardScreen(
        title: 'Auxiliares',
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: auxiliares.length,
                itemBuilder: (context, index) {
                  final aux = auxiliares[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: SizedBox(
                      height: 100,
                      child: ListTile(
                        title: Text(aux),
                        trailing: Icon(Icons.badge, color: AppColors.infoLight, size: 32),
                        onTap: () {},
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

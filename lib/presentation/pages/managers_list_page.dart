import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../components/navBar.dart';
import '../components/standartScreen.dart';

class ManagersListPage extends StatefulWidget {
  const ManagersListPage({super.key});

  @override
  State<ManagersListPage> createState() => _ManagersListPageState();
}

class _ManagersListPageState extends State<ManagersListPage> {
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

  @override
  Widget build(BuildContext context) {
    final gestores = List.generate(5, (i) => 'Gestor ${i + 1}');
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.pushNamed(context, '/user_register');
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Gestor', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.infoLight,
      ),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      body: StandardScreen(
        title: 'Gestores',
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
                itemCount: gestores.length,
                itemBuilder: (context, index) {
                  final gestor = gestores[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: SizedBox(
                      height: 100,
                      child: ListTile(
                        title: Text(gestor),
                        trailing: Icon(Icons.person, color: AppColors.infoLight, size: 32),
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

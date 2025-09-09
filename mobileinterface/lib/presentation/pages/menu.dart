import 'package:flutter/material.dart';
import '../components/standartScreen.dart';
import '../components/navBar.dart';
import '../../core/theme/app_colors.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
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
  return StandardScreen(
    title: 'Menu',
    bottomNavigationBar: CustomNavbar(
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
    ),
    child: Column(
      children: [
        _buildCard(
          icon: Icons.add_circle_outline,
          label: 'Cadastrar',
          onTap: () {
            Navigator.pushNamed(context, '/registration');
          },
        ),
        _buildCard(
          icon: Icons.list_alt,
          label: 'Pedidos',
          onTap: () {},
        ),
        _buildCard(
          icon: Icons.inventory_2,
          label: 'Estoque',
          onTap: () {},
        ),
        _buildCard(
          icon: Icons.groups,
          label: 'Gestão de usuários',
          onTap: () {},
        ),
      ],
    ),
  );
}

  Widget _buildCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
     return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 115,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                Icon(icon, color: AppColors.infoLight, size: 42),
                const SizedBox(width: 24),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
import 'package:flutter/material.dart';
import '../components/standartScreen.dart';
import '../components/navBar.dart';
import '../../core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
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
    showBackButton: false,
    bottomNavigationBar: CustomNavbar(
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            onTap: () {
              Navigator.pushNamed(context, '/order_management');
            },
          ),
          _buildCard(
            icon: Icons.inventory_2,
            label: 'Estoque',
            onTap: () {
              Navigator.pushNamed(context, '/stock');
            },
          ),
          _buildCard(
            icon: Icons.groups,
            label: 'Gestão de usuários',
            onTap: () {
              Navigator.pushNamed(context, '/user_management');
            },
          ),
          _buildCard(
            icon: Icons.local_shipping,
            label: 'Fornecedores',
            onTap: () {
              Navigator.pushNamed(context, '/supplier_management');
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoLight,
              foregroundColor: Colors.white,
              minimumSize: const Size(140, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
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
import 'package:flutter/material.dart';
import '../../components/standartScreen.dart';
import '../../components/navBar.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
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
        Navigator.pushReplacementNamed(context, '/perfil');
        break;
    }
  }

@override
Widget build(BuildContext context) {
  return StandardScreen(
    title: 'Gestão de Usuários',
    showBackButton: false,
    bottomNavigationBar: CustomNavbar(
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
            ),         
            ),
          _buildSectionHeader('Selecione', Icons.manage_accounts_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Almoxarifado',
                  description: 'Gerenciar usuários do almoxarifado',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/select_user_menu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernCard(
                  icon: Icons.local_pharmacy_rounded,
                  label: 'Farmácia',
                  description: 'Gerenciar usuários da farmácia',
                  color: const Color.fromARGB(255, 51, 194, 41),
                  onTap: () => Navigator.pushNamed(context, '/select_user_menu'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
import 'package:flutter/material.dart';
import '../components/standartScreen.dart';
import '../components/navBar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/secure_storage_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  bool _isPharmacyUser = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserSection();
  }

  Future<void> _checkUserSection() async {
    final storage = SecureStorageService();
    final user = await storage.getUser();
    
    setState(() {
      // sessionId armazena o ID da seção do usuário
      _isPharmacyUser = user?.sessionId == '2';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StandardScreen(
      title: 'Menu Principal',
      showBackButton: false,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.infoLight.withValues(alpha: 0.8),
                    AppColors.infoLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.infoLight.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bem-vindo!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'O que você gostaria de fazer hoje?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionHeader('Ações Principais', Icons.star_rounded),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 160,
              ),
              children: [
                _buildModernCard(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Cadastrar',
                  description: 'Novos produtos',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/register_product'),
                ),
                _buildModernCard(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Escanear',
                  description: 'Escanear QR Code',
                  color: const Color.fromARGB(255, 190, 50, 69),
                  onTap: () => Navigator.pushNamed(context, '/scanner'),
                ),
                _buildModernCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Estoque',
                  description: 'Gerenciar produtos',
                  color: AppColors.infoLight,
                  onTap: () => Navigator.pushNamed(context, '/stock'),
                ),
                _buildModernCard(
                  icon: Icons.list_alt_rounded,
                  label: 'Pedidos',
                  description: 'Acompanhar status',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/order_management'),
                ),
                _buildModernCard(
                  icon: Icons.local_shipping_rounded,
                  label: 'Ordens de Compra',
                  description: 'Gerenciar ordens de compra',
                  color: Colors.indigo,
                  onTap: () => Navigator.pushNamed(context, '/purchase_orders'),
                ),
                // Mostra o card de Validade apenas para usuários da seção 2 (Farmácia)
                if (_isPharmacyUser)
                  _buildModernCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Validade',
                    description: 'Controle de vencimentos',
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, '/pharmacy/expiry'),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.infoLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.infoLight, size: 20),
        ),
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
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.8), color],
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
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryLight,
            AppColors.infoLight,      
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex,
        onTap: (index) {
          onTap(index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/menu');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/user_profile');
              break;
          }
        },
        iconSize: 32,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
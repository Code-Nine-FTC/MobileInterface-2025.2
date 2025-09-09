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
          onTap(index); // atualiza o estado
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/cards');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/perfil');
              break;
          }
        },
        iconSize: 32,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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
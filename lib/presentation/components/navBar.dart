import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/api/auth_api_data_source.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../domain/entities/user.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  void _handleNavigation(BuildContext context, int index) async {
    onTap(index);

    final profileService = ProfileService(
      AuthRepositoryImpl(
        apiDataSource: AuthApiDataSource(),
        storageService: SecureStorageService(),
      ),
    );

    User? currentUser = await profileService.getCurrentUser();
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    switch (index) {
      case 0:
        final targetRoute = currentUser?.role == 'ADMIN'
            ? '/admin_menu'
            : '/menu';
        if (currentRoute != targetRoute) {
          Navigator.pushReplacementNamed(context, targetRoute);
        }
        break;
      case 1:
        if (currentRoute != '/user_profile') {
          Navigator.pushReplacementNamed(context, '/user_profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryLight, AppColors.infoLight],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
        iconSize: 32,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

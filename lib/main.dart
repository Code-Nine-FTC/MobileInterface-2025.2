import 'package:flutter/material.dart';
import 'presentation/pages/loginPage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/menu.dart';
import 'presentation/pages/registrationPage.dart';
import 'presentation/pages/user_management_page.dart';
import 'presentation/pages/order_management_page.dart';
import 'presentation/pages/assistants_list_page.dart';
import 'presentation/pages/managers_list_page.dart';
import 'presentation/pages/stock_list_page.dart';
import 'presentation/pages/user_register_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Meu App',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/login':
              builder = (context) => const LoginPage();
              break;
            case '/menu':
              builder = (context) => const MenuPage();
              break;
            case '/product_register':
              builder = (context) => const RegistrationPage();
              break;
            case '/user_management':
              builder = (context) => const UserManagementPage();
              break;
            case '/order_management':
              builder = (context) => const OrderManagementPage();
              break;
            case '/assistants':
              builder = (context) => const AssistantsListPage();
              break;
            case '/managers':
              builder = (context) => const ManagersListPage();
              break;
            case '/stock':
              builder = (context) => const StockListPage();
              break;
            case '/user_register':
              builder = (context) => UserRegisterPage();
              break;
            default:
              builder = (context) => const MenuPage();
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => builder(context),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            settings: settings,
          );
        },
        routes: {
          '/login': (context) => const LoginPage(),
          '/menu': (context) => const MenuPage(),
          '/registration': (context) => const RegistrationPage(),
          '/user_management': (context) => const UserManagementPage(),
          '/order_management': (context) => const OrderManagementPage(),
          '/assistants': (context) => const AssistantsListPage(),
          '/managers': (context) => const ManagersListPage(),
          '/stock': (context) => const StockListPage(),
          '/user_register': (context) => UserRegisterPage(),
        },
      ),
    );
  }
}
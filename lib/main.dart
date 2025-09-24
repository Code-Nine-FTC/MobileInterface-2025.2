import 'package:flutter/material.dart';
import 'presentation/pages/loginPage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/menu.dart';
import 'presentation/pages/user/registrationPage.dart';
import 'presentation/pages/user/user_management_page.dart';
import 'presentation/pages/order/order_management_page.dart';
import 'presentation/pages/user/assistants_list_page.dart';
import 'presentation/pages/user/managers_list_page.dart';
import 'presentation/pages/stock/stock_list_page.dart';
import 'presentation/pages/stock/stock_detail_page.dart';
import 'presentation/pages/user/user_register_page.dart';
import 'presentation/pages/supplier/registration_supplier_page.dart';
import 'presentation/pages/supplier/list_supplier_simple.dart';
import 'presentation/pages/supplier/supplier_details_page.dart';
import 'presentation/pages/user/user_profile.dart';
import 'presentation/pages/adiminMenu.dart';
import 'presentation/pages/user/select_user_menu.dart';
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
            case '/admin_menu':
              builder = (context) => const AdiminMenuPage();
              break;
            case '/select_user_menu':
              builder = (context) => const SelectUserMenu();
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
            case '/stock_detail':
              final args = settings.arguments as Map<String, dynamic>?;
              final id = args?['id']?.toString();
              final data = args?['data'] as Map<String, dynamic>?;
              builder = (context) =>
                  StockDetailPage(itemId: id, itemData: data);
              break;
            case '/user_register':
              builder = (context) => UserRegisterPage();
              break;
            case '/supplier_register':
              builder = (context) => const RegistrationSupplierPage();
              break;
            case '/supplier_management':
              builder = (context) => const ListSupplierPage();
              break;
            case '/supplier_details':
              final supplierId = settings.arguments as String?;
              if (supplierId != null) {
                builder = (context) => SupplierDetailsPage(supplierId: supplierId);
              } else {
                builder = (context) => const ListSupplierPage();
              }
              break;
            case '/user_profile':
              builder = (context) => const UserProfile();
              break;
            default:
              builder = (context) => const MenuPage();
          }
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: Curves.ease));
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
          '/supplier_register': (context) => const RegistrationSupplierPage(),
          '/supplier_management': (context) => const ListSupplierPage(),
          '/user_profile': (context) => const UserProfile(),
        },
      ),
    );
  }
}

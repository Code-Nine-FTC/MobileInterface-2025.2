import 'package:flutter/material.dart';
import 'presentation/pages/loginPage.dart';
import 'presentation/pages/home.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/menu.dart';

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
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/menu': (context) => const MenuPage(),
        },
      ),
    );
  }
}
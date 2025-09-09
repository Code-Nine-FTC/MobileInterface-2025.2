import 'package:flutter/material.dart';
import '../../../main.dart';
import '../components/navBar.dart'; 

class HomePage extends StatefulWidget { 
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aqui você pode trocar o conteúdo do body conforme o index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        actions: [
          Row(
            children: [
              Icon(Icons.light_mode, color: Theme.of(context).colorScheme.primary),
              Switch(
                value: themeNotifier.value == ThemeMode.dark,
                onChanged: (value) {
                  themeNotifier.value =
                      value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Text("Use o switch no AppBar para alternar entre Light e Dark."),
      ),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

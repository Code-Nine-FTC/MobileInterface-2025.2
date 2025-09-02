import 'package:flutter/material.dart';
import '../../../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              const SizedBox(width: 12), // espaçamento final
            ],
          ),
        ],
      ),
      body: const Center(
        child: Text("Use o switch no AppBar para alternar entre Light e Dark."),
      ),
    );
  }
}

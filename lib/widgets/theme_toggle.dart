import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Light mode' : 'Dark mode',
      icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => setDarkMode(!dark),
    );
  }
}

Future<void> setDarkMode(bool dark) async {
  themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark', dark);
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF111713) : const Color(0xFFF5F6F1);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF2D6A4F),
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.dmSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : Colors.black87,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1E1E28) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : Colors.black87,
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  themeMode.value = (prefs.getBool('dark') ?? false)
      ? ThemeMode.dark
      : ThemeMode.light;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Job Portal Mobile App',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : const Color(0xFFE3E6DF),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRect(child: child!),
            ),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snap.hasData ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}

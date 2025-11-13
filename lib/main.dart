import 'package:abc_app/checkuser.dart';
import 'package:abc_app/loginpage.dart';
import 'package:abc_app/screens/onboarding1.dart';
import 'package:abc_app/screens/onboarding2.dart';
import 'package:abc_app/screens/settings_screen.dart';
import 'package:abc_app/screens/splash_screen.dart';
import 'package:abc_app/signup.dart';
import 'package:abc_app/widgets/bottom_navbar.dart';
import 'package:abc_app/widgets/pharmacy_bottom_navbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('app_theme') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_theme', mode == ThemeMode.dark);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeNotifier()..loadTheme(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'UrMedio App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: themeNotifier.themeMode,

            home: const Checkuser(),

            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding1': (context) => const Onboarding1(),
              '/onboarding2': (context) => const Onboarding2(),
              '/login': (context) => const Loginpage(),
              '/signup': (context) => const Signup(),
              '/patient_home': (context) => const BottomNavbar(),
              '/pharmacy_home': (context) => const PharmacyBottomNavbar(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:item_shop/pages/main.dart';
import 'package:item_shop/pages/welcomeapp_page.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.instance.loadTheme();

  runApp(const ItemShopApp());
}

class ItemShopApp extends StatelessWidget {
  const ItemShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, child) {
        final isDark = ThemeController.instance.isDark;

        const green = Color(0xFF174D3A);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Barkas',

          // LOCALIZATION
          locale: const Locale('id'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id'),
            Locale('en'),
          ],

          // THEME MODE
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F8F4),
            colorScheme: ColorScheme.fromSeed(
              seedColor: green,
              brightness: Brightness.light,
              primary: green,
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F8F4),
              foregroundColor: Color(0xFF26352D),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121A16),
            colorScheme: ColorScheme.fromSeed(
              seedColor: green,
              brightness: Brightness.dark,
              primary: const Color(0xFF75B99A),
              surface: const Color(0xFF1D2922),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121A16),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
            ),
          ),

          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkLogin() async {
    final token = await ApiService.getToken();

    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainPage();
        }

        return const WelcomePage();
      },
    );
  }
}

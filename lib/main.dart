import 'package:flutter/material.dart';
import 'package:onderliftmobil/pages/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/adminpanel.dart';
import 'package:onderliftmobil/pages/subuser.dart';
import 'package:onderliftmobil/pages/languageprovider.dart'; // LanguageProvider'ı ekleyin
import 'package:onderliftmobil/pages/login.dart';
import 'package:onderliftmobil/pages/signup.dart';
import 'package:onderliftmobil/pages/AnaSayfa.dart';
import 'package:onderliftmobil/pages/bakim.dart';
import 'package:onderliftmobil/pages/hata.dart';
import 'package:onderliftmobil/pages/belge.dart';
import 'package:onderliftmobil/pages/profil.dart';
import 'package:onderliftmobil/pages/profiledit.dart';
import 'package:onderliftmobil/pages/ayarlar.dart';
import 'package:onderliftmobil/pages/makineler.dart';
import 'package:onderliftmobil/pages/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return MaterialApp(
          theme: lightTheme,  // theme.dart'tan gelen lightTheme'i kullanıyoruz.
          darkTheme: darkTheme,  // theme.dart'tan gelen darkTheme'i kullanıyoruz.
          themeMode: themeProvider.themeMode,
          home: Scaffold(
            body: LoginScreen(),
          ),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/main': (context) => AnaSayfa(),
            '/belge': (context) => BelgeScreen(),
            '/profil': (context) => ProfilScreen(),
            '/profil2': (context) => ProfilEditScreen(),
            '/ayar': (context) => AyarlarScreen(),
            '/makineler': (context) => MakinelerScreen(),
            '/admin': (context) => AdminScreen(),
            '/sub': (context) => SubUserScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/bakim') {
              final args = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) {
                  return BakimScreen(machineID: args);
                },
              );
            }
            if (settings.name == '/hata') {
              final args = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) {
                  return HataScreen(machineID: args);
                },
              );
            }
            return null;
          },
        );
      },
    );
  }
}
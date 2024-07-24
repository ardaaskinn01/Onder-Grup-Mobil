import 'package:flutter/material.dart';
import 'package:onderliftmobil/firebase_options.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Arka plan ve metin renklerini buradan değiştirebilirsiniz
        cardColor: Colors.black,
      ),
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
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/bakim') {
          final args = settings.arguments as String; // `machineId`'yi `arguments` olarak bekliyoruz
          return MaterialPageRoute(
            builder: (context) {
              return BakimScreen(machineID: args);
            },
          );
        }
        if (settings.name == '/hata') {
          final args = settings.arguments as String; // `machineId`'yi `arguments` olarak bekliyoruz
          return MaterialPageRoute(
            builder: (context) {
              return HataScreen(machineID: args);
            },
          );
        }
        // Diğer rotalar için null döndürebilirsiniz veya varsayılan bir rota belirleyebilirsiniz
        return null;
      },
    );
  }
}

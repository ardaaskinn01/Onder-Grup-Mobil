import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/pages/profiledit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

final storage = FlutterSecureStorage();

String? name = "";
String? username = "";
String? email = "";
String? companyName = "";
String? phoneNumber = "";

class ProfilScreen extends StatefulWidget {
  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    String? token = await storage.read(key: 'token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('http://85.95.231.92:3001/api/users/userInfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        setState(() {
          name = userData['name'];
          email = userData['email'];
          username = userData['username'];
          companyName = userData['companyname'];
          phoneNumber = userData['phonenumber'];
        });
      } else {
        // Hata durumunu ele al
        print('Failed to load user data: ${response.body}');
      }
    } else {
      print('Token is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    // LanguageProvider'ı ekliyoruz
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.selectedLanguage == 'Türkçe' ? 'Profil' : 'Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileItem(
                    languageProvider.selectedLanguage == 'Türkçe' ? 'İsim' : 'Name',
                    name,
                  ),
                  const Divider(),
                  _buildProfileItem(
                    languageProvider.selectedLanguage == 'Türkçe' ? 'E-mail' : 'Email',
                    email,
                  ),
                  const Divider(),
                  _buildProfileItem(
                    languageProvider.selectedLanguage == 'Türkçe' ? 'Kullanıcı Adı' : 'Username',
                    username,
                  ),
                  const Divider(),
                  _buildProfileItem(
                    languageProvider.selectedLanguage == 'Türkçe' ? 'Şirket Adı' : 'Company Name',
                    companyName,
                  ),
                  const Divider(),
                  _buildProfileItem(
                    languageProvider.selectedLanguage == 'Türkçe' ? 'Telefon Numarası' : 'Phone Number',
                    phoneNumber,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Profil düzenleme ekranına git ve dönüşte güncelle
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilEditScreen()),
                  );
                  // Profil düzenlemeden dönüldüğünde verileri yeniden yükle
                  _getUserData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222F5A),
                  padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 22.0),
                ),
                child: Text(
                  languageProvider.selectedLanguage == 'Türkçe' ? 'Profili Düzenle' : 'Edit Profile',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String title, String? value) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12.0),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        subtitle: Text(
          value ?? '',
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
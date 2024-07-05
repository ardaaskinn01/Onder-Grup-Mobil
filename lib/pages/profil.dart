import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/pages/profiledit.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? name = "";
String? username = "";
String? email = "";

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getUserProfile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          name = userData['name'];
          email = userData['email'];
          username = userData['username'];
        });
      } else {
        // Hata durumunu ele al
        print('Failed to load user data${response.body}');
      }
    } else {
      print('Token is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
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
                  _buildProfileItem('Name', name),
                  Divider(),
                  _buildProfileItem('Email', email),
                  Divider(),
                  _buildProfileItem('Username', username),
                  SizedBox(height: 20.0),
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
                  backgroundColor: Color(0xFF222F5A),
                  padding: EdgeInsets.symmetric(horizontal: 60.0, vertical: 22.0),
                ),
                child: Text(
                  'Profili Düzenle',
                  style: TextStyle(
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
      padding: EdgeInsets.all(12.0),
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        subtitle: Text(
          value ?? '',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
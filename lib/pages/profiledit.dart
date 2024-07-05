import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilEditScreen extends StatefulWidget {
  @override
  _ProfilEditState createState() => _ProfilEditState();
}

class _ProfilEditState extends State<ProfilEditScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();

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
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _usernameController.text = userData['username'] ?? '';
        });
      } else {
        print('Failed to load user data: ${response.body}');
      }
    } else {
      print('Token is null');
    }
  }


  Future<void> _updateProfile() async {
    final String apiUrl = 'http://10.0.2.2:3000/updateUserProfile';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (_nameController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun.'),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'username': _usernameController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profil başarıyla güncellendi.'),
        ));
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('Failed to update profile: ${errorResponse['error']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profil güncelleme hatası: $e'),
      ));
      print('Error updating profile: $e');
    }
  }

  Future<void> _changePassword(String newPassword) async {
    final String apiUrl = 'http://10.0.2.2:3000/changePassword';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen oturum açın.'),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['message'] == 'Password changed successfully') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Parola başarıyla güncellendi.'),
          ));
        } else {
          throw Exception('Parola güncelleme başarısız oldu: ${responseData['error']}');
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('Parola güncelleme başarısız oldu: ${errorResponse['error']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Parola güncelleme hatası: $e'),
      ));
      print('Error changing password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Edit'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileItem('Name', _nameController),
                  _buildProfileItem('Email', _emailController, editable: false),
                  _buildProfileItem('Username', _usernameController),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0.0),
                    child: _buildChangePasswordButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String title, TextEditingController controller, {bool editable = true}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              Text(
                controller.text,
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
          editable
              ? ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Edit $title'),
                    content: TextField(
                      controller: controller,
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _updateProfile();
                        },
                        child: Text('Kaydet'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('İptal'),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF222F5A),
              padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
            ),
            child: Text(
              'Düzenle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
            ),
          )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            TextEditingController newPasswordController = TextEditingController();

            return AlertDialog(
              title: Text('Parola Değiştir'),
              content: TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Parola',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    await _changePassword(newPasswordController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text('Kaydet'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('İptal'),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF222F5A),
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
      ),
      child: Text(
        'Parola Değiştir',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
          fontSize: 15,
        ),
      ),
    );
  }
}

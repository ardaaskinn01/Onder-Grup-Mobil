import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

final storage = FlutterSecureStorage();

String? name = "";
String? userID = "";
String? email = "";
String? phone = ""; // Telefon numarası alanı

class ProfilEditScreen extends StatefulWidget {
  @override
  _ProfilEditState createState() => _ProfilEditState();
}

class _ProfilEditState extends State<ProfilEditScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

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
          phone = userData['phoneNumber']; // Telefon numarasını ekleyin
          userID = userData['userID'];

          _nameController.text = name!;
          _emailController.text = email!;
          _phoneController.text = phone!; // Telefon numarasını ekleyin
        });
      } else {
        // Hata durumunu ele al
        print('Failed to load user data: ${response.body}');
      }
    } else {
      print('Token is null');
    }
  }

  Future<void> _updateProfile(BuildContext context) async {
    String? token = await storage.read(key: 'token');
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/updateUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userID': userID,
          'userData': {
            'name': _nameController.text,
            'email': _emailController.text,
            'phoneNumber': _phoneController.text,
          },
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.getLocalizedString('profile_updated_successfully')),
        ));
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('${languageProvider.getLocalizedString('profile_update_failed')} ${errorResponse['error']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${languageProvider.getLocalizedString('profile_update_failed')} $e'),
      ));
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(languageProvider.getLocalizedString('edit')),
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
                  _buildProfileItem(languageProvider.getLocalizedString('name'), _nameController),
                  _buildProfileItem(languageProvider.getLocalizedString('email'), _emailController),
                  _buildProfileItem(languageProvider.getLocalizedString('phoneNumber'), _phoneController), // Telefon numarası alanı
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0.0),
                    child: _buildChangePasswordButton(languageProvider),
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
                    title: Text(title),
                    content: TextField(
                      controller: controller,
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _updateProfile(context);
                        },
                        child: Text(Provider.of<LanguageProvider>(context).getLocalizedString('save')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(Provider.of<LanguageProvider>(context).getLocalizedString('cancel')),
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
              Provider.of<LanguageProvider>(context).getLocalizedString('edit'),
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

  Widget _buildChangePasswordButton(LanguageProvider languageProvider) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            TextEditingController newPasswordController = TextEditingController();
            TextEditingController oldPasswordController = TextEditingController();

            return AlertDialog(
              title: Text(languageProvider.getLocalizedString('change_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: languageProvider.getLocalizedString('old_password'),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: languageProvider.getLocalizedString('new_password'),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    await _changePassword(context, oldPasswordController.text, newPasswordController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text(languageProvider.getLocalizedString('save')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(languageProvider.getLocalizedString('cancel')),
                ),
              ],
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF222F5A),
        padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
      ),
      child: Text(
        languageProvider.getLocalizedString('change_password'),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, String oldPassword, String newPassword) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    String? token = await storage.read(key: 'token');

    try {
      final response = await http.post(
        Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/changePassword'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(languageProvider.getLocalizedString('password_updated_successfully')),
        ));
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('${languageProvider.getLocalizedString('password_update_failed')} ${errorResponse['error']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${languageProvider.getLocalizedString('password_update_failed')} $e'),
      ));
      print('Error updating password: $e');
    }
  }
}
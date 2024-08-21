import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _name = '';
  String _mail = '';
  String _phone = '';
  String _company = '';
  String _username = '';
  String _password = '';

  Future<void> _handleRegister(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (_mail.isEmpty || _password.isEmpty || _name.isEmpty || _username.isEmpty) {
      _showErrorDialog(context, languageProvider.getLocalizedString('fill_all_fields'));
      return;
    }

    try {
      final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/auth/registerUser');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userName': _username,
          'nameSurname': _name,
          'eMail': _mail,
          'phoneNumber': _phone,
          'companyName': _company,
          'password': _password
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushNamed(context, "/login");
      } else {
        final responseBody = jsonDecode(response.body);
        _showErrorDialog(context, '${languageProvider.getLocalizedString('error_registering_user')}: ${responseBody['error']}');
        print('HTTP Error Response: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      _showErrorDialog(context, '${languageProvider.getLocalizedString('error_registering_user')}: $e');
      print('Error during HTTP request: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getLocalizedString('error')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(languageProvider.getLocalizedString('ok')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, "/login");
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null,
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 850.0,
              maxWidth: 850.0,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(0, -0.75),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _name = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('name'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, -0.55),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _username = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('username'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, -0.35),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _mail = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('email'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, -0.15),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _phone = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('phonenumber'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, 0.05),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _company = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('company'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, 0.25),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    heightFactor: 0.075,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _password = value;
                        });
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: languageProvider.getLocalizedString('password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, 0.55),
                  child: ElevatedButton(
                    onPressed: () {
                      _handleRegister(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBE1522),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.02,
                        horizontal: MediaQuery.of(context).size.width * 0.09,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      languageProvider.getLocalizedString('complete_registration'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _name = '';
  String _mail = '';
  String _username = '';
  String _password = '';

  Future<void> _handleRegister(BuildContext context) async {
    if (_mail.isEmpty || _password.isEmpty || _name.isEmpty || _username.isEmpty) {
      _showErrorDialog(context, 'Lütfen tüm alanları doldurun.');
      return;
    }

    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/auth/registerUser');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': _name,
          'email': _mail,
          'username': _username,
          'password': _password,
          'role': 'guest',
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushNamed(context, "/login");
      } else {
        final responseBody = jsonDecode(response.body);
        _showErrorDialog(context, 'Kullanıcı kaydedilirken bir hata oluştu: ${responseBody['error']}');
        print('HTTP Error Response: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      _showErrorDialog(context, 'Kullanıcı kaydedilirken bir hata oluştu: $e');
      print('Error during HTTP request: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Tamam'),
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
    return WillPopScope(
      // Geri tuşuna basıldığında
      onWillPop: () async {
        // Login ekranına geri dön
        Navigator.pushNamed(context, "/login");
        // Geri tuşunun varsayılan işlevini devre dışı bırak
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
                  alignment: Alignment(0, -0.6),
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
                        hintText: 'İsim',
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
                          _username = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Kullanıcı Adı',
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
                  alignment: Alignment(0, -0.1),
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
                        hintText: 'E-Mail',
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
                  alignment: Alignment(0, 0.15),
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
                        hintText: 'Şifre',
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
                  alignment: Alignment(0, 0.45),
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
                      'Kaydı Tamamla',
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
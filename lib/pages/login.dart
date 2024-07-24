import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:onderliftmobil/pages/AnaSayfa.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mail = '';
  String _password = '';

  Future<void> _handleLogin(BuildContext context) async {
    if (_mail.isEmpty || _password.isEmpty) {
      _showErrorDialog(context, 'Lütfen kullanıcı adı ve şifre girin.');
      return;
    }

    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _mail, 'password': _password}),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final data = json.decode(response.body);
          final token = data['token'];

          // Token'ı ve email'i SharedPreferences ile saklama
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('email', _mail);  // Email'i saklama işlemi

          print('Token saved: $token');
          print('Email saved: $_mail');

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnaSayfa()),
          );
        } else {
          print('Beklenmeyen içerik tipi: $contentType');
          _showErrorDialog(context, 'Sunucudan beklenmeyen bir yanıt alındı.');
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(context, 'Giriş başarısız: ${errorResponse['error']}');
      }
    } catch (e) {
      _showErrorDialog(context, 'Giriş yapılırken bir hata oluştu: $e');
    }
  }


  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _handleSignUp(BuildContext context) {
    Navigator.pushNamed(context, "/register");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: null,
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 850.0,
            maxWidth: 850.0,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment(0, -0.9),
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  heightFactor: 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, -0.3),
                child: FractionallySizedBox(
                  heightFactor: 0.075,
                  widthFactor: 0.8,
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, -0.1),
                child: FractionallySizedBox(
                  heightFactor: 0.075,
                  widthFactor: 0.8,
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
                          width: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.2),
                child: ElevatedButton(
                  onPressed: () {
                    _handleLogin(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF222F5A),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Giriş Yap',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.4),
                child: ElevatedButton(
                  onPressed: () {
                    _handleSignUp(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFBE1522),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.21,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Kayıt Ol',
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
    );
  }
}

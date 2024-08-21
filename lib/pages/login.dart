import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:onderliftmobil/pages/AnaSayfa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

final storage = FlutterSecureStorage();

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _username = '';
  String _password = '';

  Future<void> _handleLogin(BuildContext context) async {
    if (_username.isEmpty || _password.isEmpty) {
      _showErrorDialog(context, 'Lütfen kullanıcı adı ve şifre girin.');
      return;
    }

    try {
      final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userName': _username, 'password': _password}),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final data = json.decode(response.body);
          final token = data['token'];

          await storage.write(key: 'token', value: token);
          await storage.write(key: 'username', value: _username);

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
    final languageProvider = Provider.of<LanguageProvider>(context); // LanguageProvider'ı kullanıyoruz

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
                        _username = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: languageProvider.selectedLanguage == 'Türkçe'
                          ? 'Kullanıcı Adı'
                          : 'Username',
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
                      hintText: languageProvider.selectedLanguage == 'Türkçe'
                          ? 'Şifre'
                          : 'Password',
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
                    languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Giriş Yap'
                        : 'Login',
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
                    languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Kayıt Ol'
                        : 'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.6),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasswordResetScreen(),
                      ),
                    );
                  },
                  child: Text(
                    languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Parolamı Unuttum'
                        : 'Forgot Password',
                    style: TextStyle(
                      color: Colors.black,
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

class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  String _newPassword = '';
  String _confirmPassword = '';
  String _username = '';

  Future<void> _resetPassword() async {
    if (_newPassword.isEmpty || _confirmPassword.isEmpty || _username.isEmpty) {
      _showErrorDialog('Lütfen tüm alanları doldurun.');
      return;
    }

    if (_newPassword != _confirmPassword) {
      _showErrorDialog('Şifreler eşleşmiyor.');
      return;
    }

    try {
      final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/auth/resetPass');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _username, 'password': _newPassword, 'otpSentTime': ''}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Önceki ekrana geri dön
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog('Şifre sıfırlama başarısız: ${errorResponse['error']}');
      }
    } catch (e) {
      _showErrorDialog('Şifre sıfırlama sırasında bir hata oluştu: $e');
    }
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context); // LanguageProvider'ı kullanıyoruz

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(languageProvider.selectedLanguage == 'Türkçe'
            ? 'Şifre Sıfırlama'
            : 'Password Reset'),
        backgroundColor: Color(0xFF222F5A),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 600.0,
            maxWidth: 600.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FractionallySizedBox(
                heightFactor: 0.1,
                widthFactor: 0.8,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _username = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Kullanıcı Adı'
                        : 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              FractionallySizedBox(
                heightFactor: 0.1,
                widthFactor: 0.8,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _newPassword = value;
                    });
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Yeni Şifre'
                        : 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              FractionallySizedBox(
                heightFactor: 0.1,
                widthFactor: 0.8,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _confirmPassword = value;
                    });
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Şifreyi Onayla'
                        : 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
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
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Şifreyi Sıfırla'
                      : 'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'languageprovider.dart';

final storage = FlutterSecureStorage();

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    String? token = await storage.read(key: 'token');
    final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/getAllUsers');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          // 'sysop' rolüne sahip kullanıcıları filtreleyin
          _users = json.decode(response.body).where((user) => user['role'] != 'sysop').toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      print('Error fetching users: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(int userId) async {
    String? token = await storage.read(key: 'token');
    final url = Uri.parse('http://85.95.231.92:3001/api/users/deleteUser');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({'userID': userId});

    try {
      final response = await http.delete(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
        });
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (error) {
      print('Error deleting user: $error');
    }
  }

  Future<void> _updateUserRole(int username, String newRole) async {
    String? token = await storage.read(key: 'token');
    final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/updateRole');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({'newRole': newRole, 'userName': username});

    try {
      final response = await http.put(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        setState(() {
          final userIndex = _users.indexWhere((user) => user['userName'] == username);
          if (userIndex != -1) {
            _users[userIndex]['role'] = newRole;
          }
        });
      } else {
        throw Exception('Failed to update user role');
      }
    } catch (error) {
      print('Error updating user role: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.selectedLanguage == 'Türkçe'
              ? 'Kullanıcılar'
              : 'Users',
        ),
        backgroundColor: Color(0xFF222F5A),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: Icon(Icons.person, color: Color(0xFF222F5A)),
              title: Text(user['name'] ?? 'No Name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? 'No E-mail'),
                  Text('Role: ${user['role'] ?? 'No Role'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF222F5A)),
                    onPressed: () {
                      _showRoleUpdateDialog(user['userName'], user['userType']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFBE1522)),
                    onPressed: () {
                      _deleteUser(user['id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoleUpdateDialog(int username, String currentRole) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final TextEditingController _roleController = TextEditingController(text: currentRole);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Rolü Güncelle'
                : 'Update Role',
          ),
          content: TextField(
            controller: _roleController,
            decoration: InputDecoration(hintText: languageProvider.selectedLanguage == 'Türkçe'
                ? 'Yeni Rolü Girin'
                : 'Enter the New Role',),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateUserRole(username, _roleController.text);
                Navigator.of(context).pop();
              },
              child:  Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'Güncelle'
                    : 'Update',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:  Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'İptal'
                    : 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }
}
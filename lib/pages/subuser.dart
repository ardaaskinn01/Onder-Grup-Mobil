import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

final storage = FlutterSecureStorage();

class SubUserScreen extends StatefulWidget {
  @override
  _SubUserScreenState createState() => _SubUserScreenState();
}

class _SubUserScreenState extends State<SubUserScreen> {
  List<Map<String, dynamic>> _subUsers = [];

  @override
  void initState() {
    super.initState();
    _getSubUsers();
  }

  Future<void> _getSubUsers() async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/getAllSubUsers');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> subUsersData = jsonDecode(response.body);
        setState(() {
          _subUsers = subUsersData.map((data) => data as Map<String, dynamic>).toList();
        });
      } else {
        print('Failed to fetch sub-users');
      }
    } catch (e) {
      print('Error fetching sub-users: $e');
    }
  }

  Future<void> _showAddSubUserDialog({Map<String, dynamic>? user}) async {
    final TextEditingController nameController = TextEditingController(text: user?['name'] ?? '');
    final TextEditingController usernameController = TextEditingController(text: user?['username'] ?? '');
    final TextEditingController emailController = TextEditingController(text: user?['email'] ?? '');
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'engineer';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final languageProvider = context.watch<LanguageProvider>();

        return AlertDialog(
          title: Text(user != null
              ? languageProvider.getLocalizedString('editUser')
              : languageProvider.getLocalizedString('addSubUser')),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(nameController, languageProvider.getLocalizedString('name')),
                _buildTextField(usernameController, languageProvider.getLocalizedString('username')),
                _buildTextField(emailController, languageProvider.getLocalizedString('email')),
                _buildTextField(passwordController, languageProvider.getLocalizedString('password'), obscureText: true),
                SizedBox(height: 16.0),
                _buildRoleDropdown(selectedRole, languageProvider.getLocalizedString('role'), (String? newRole) {
                  if (newRole != null) {
                    setState(() {
                      selectedRole = newRole;
                    });
                  }
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageProvider.getLocalizedString('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (user == null) {
                  await _createSubUser(
                    nameController.text,
                    usernameController.text,
                    emailController.text,
                    passwordController.text,
                    selectedRole,
                  );
                } else {
                  await _editSubUser(
                    user['id'],
                    nameController.text,
                    usernameController.text,
                    emailController.text,
                    passwordController.text,
                    selectedRole,
                  );
                }
                Navigator.of(context).pop();
                _getSubUsers();
              },
              child: Text(user != null
                  ? languageProvider.getLocalizedString('edit')
                  : languageProvider.getLocalizedString('add')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleDropdown(String currentRole, String label, Function(String?) onChanged) {
    final languageProvider = context.watch<LanguageProvider>();

    return DropdownButtonFormField<String>(
      value: currentRole,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: 'engineer',
          child: Text(languageProvider.getLocalizedString('engineer')),
        ),
        DropdownMenuItem(
          value: 'technician',
          child: Text(languageProvider.getLocalizedString('technician')),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint),
      obscureText: obscureText,
    );
  }

  Future<void> _createSubUser(String name, String username, String email, String password, String role) async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse('http://85.95.231.92:3001/api/sub/createSubUser');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        print('Sub-user created successfully');
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Failed to create sub-user: ${errorResponse['error']}');
      }
    } catch (e) {
      print('Error creating sub-user: $e');
    }
  }

  Future<void> _editSubUser(int id, String name, String username, String email, String password, String role) async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse('http://85.95.231.92:3001/api/sub/editSubUser');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': id, // Include the id in the request body
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        print('Sub-user edited successfully');
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Failed to edit sub-user: ${errorResponse['error']}');
      }
    } catch (e) {
      print('Error editing sub-user: $e');
    }
  }

  Future<void> _deleteSubUser(int id) async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse('http://85.95.231.92:3001/api/sub/deleteSubUser');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id}), // Pass the id in the request body
      );

      if (response.statusCode == 200) {
        _getSubUsers(); // Refresh list after deletion
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Failed to delete sub-user: ${errorResponse['error']}');
      }
    } catch (e) {
      print('Error deleting sub-user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getLocalizedString('users')), // 'Kullanıcılar'
        backgroundColor: Color(0xFFBE1522),
      ),
      body: Stack(
        children: [
          _subUsers.isEmpty
              ? Center(
            child: Text(languageProvider.getLocalizedString('noSubUsersFound')),
          )
              : ListView.builder(
            itemCount: _subUsers.length,
            itemBuilder: (context, index) {
              final user = _subUsers[index];
              return ListTile(
                title: Text(user['name'] ?? languageProvider.getLocalizedString('noName')),
                subtitle: Text(user['role'] ?? languageProvider.getLocalizedString('noRole')),
                trailing: Wrap(
                  spacing: 12, // İki ikon arasındaki boşluk
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showAddSubUserDialog(user: user);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteSubUser(user['id']); // Silme işlemi için id'yi geç
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddSubUserDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF222F5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  languageProvider.getLocalizedString('addSubUser'), // 'Alt Kullanıcı Ekle'
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

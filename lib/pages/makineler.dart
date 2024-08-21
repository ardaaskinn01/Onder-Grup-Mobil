import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bakim.dart';
import 'hata.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

final storage = const FlutterSecureStorage();

late String role = '';

class MakinelerScreen extends StatefulWidget {
  @override
  @override
  _MakinelerScreenState createState() => _MakinelerScreenState();
}

class _MakinelerScreenState extends State<MakinelerScreen> {

  void initState() {
    super.initState();
    getUserRole();
  }

  Future<void> getUserRole() async {
    try {
      String? username = await storage.read(key: 'username');
      String? token = await storage.read(key: 'token');
      final url = Uri.parse('http://85.95.231.92:3001/api/users/getRole?username=$username');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          role = data['role'];
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<List<dynamic>> _getMachines() async {
    String? token = await storage.read(key: 'token');
    try {
      Uri url;
      if (role == 'sysop' || role == 'technician') {
        url = Uri.parse('http://85.95.231.92:3001/api/machines/getAllMachines');
      } else {
        url = Uri.parse('http://85.95.231.92:3001/api/machines/getMachines');
      }
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load machines');
      }
    } catch (e) {
      throw Exception('Error occurred while fetching machines: $e');
    }
  }

  Future<void> deleteMachine(String machineID) async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse(
          'http://85.95.231.92:3001/api/machines/delete?machineID=$machineID'); // Yeni backend URL'sini kullanın
      final response = await http.delete(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('Machine deleted successfully: ${response.body}');
      } else {
        print('Failed to delete machine. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting machine: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: null,
      body: Center(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FutureBuilder(
                      future: _getMachines(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData) {
                          return Text(
                            languageProvider.selectedLanguage == 'Türkçe'
                                ? 'Veri bulunamadı'
                                : 'No data found',
                          );
                        }
                        var machines = snapshot.data as List;
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 35,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      languageProvider.selectedLanguage == 'Türkçe'
                                          ? '  ID'
                                          : '  ID',
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      languageProvider.selectedLanguage == 'Türkçe'
                                          ? ' İsim'
                                          : ' Name',
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      languageProvider.selectedLanguage == 'Türkçe'
                                          ? 'Tür'
                                          : 'Type',
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      languageProvider.selectedLanguage == 'Türkçe'
                                          ? ' İncele'
                                          : ' View',
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      languageProvider.selectedLanguage == 'Türkçe'
                                          ? '    Sil'
                                          : ' Delete',
                                    ),
                                  ),
                                ],
                                rows: machines.map((machine) {
                                  return DataRow(cells: [
                                    DataCell(
                                      Text(
                                        machine['machineID'].toString(),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        machine['machineName'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        machine['machineType'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: Color(0xFF222F5A)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MachineScreen(
                                                      machineID:
                                                      machine['machineID']),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Color(0xFFBE1522)),
                                        onPressed: () {
                                          if (role == 'sysop' ||
                                              role == 'engineer') {
                                            var machineIdToDelete =
                                            machine['machineID'].toString();
                                            deleteMachine(machineIdToDelete);
                                            setState(() {}); // UI'yı güncelle
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  languageProvider
                                                      .selectedLanguage ==
                                                      'Türkçe'
                                                      ? 'Yetkiniz yok'
                                                      : 'You do not have permission',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MachineScreen extends StatefulWidget {
  @override
  _MachineScreenState createState() => _MachineScreenState();
  final int machineID;

  MachineScreen({required this.machineID});
}

class _MachineScreenState extends State<MachineScreen> {

  String eepromData1 = 'eepromData38';
  String eepromData2 = 'eepromData39';
  String eepromData3 = 'eepromData40';
  String eepromData4 = 'eepromData41';
  String eepromData5 = 'eepromData42';
  String eepromData6 = 'eepromData43';
  String eepromData7 = 'eepromData44';
  String eepromData8 = 'eepromData45';
  String eepromData9 = 'eepromData46';
  String eepromData10 = 'eepromData47';
  late String machineName = '';
  late String machineID = '';
  late String machineType = '';
  late Map<String, dynamic> machineDetails = {};

  @override
  void initState() {
    super.initState();
    _getMachineDetails();
  }

  Future<void> _getMachineDetails() async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse(
          'http://85.95.231.92:3001/api/machines/details?machineID=${widget.machineID}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          machineName = data['machineName'];
          machineID = data['machineID'].toString();
          machineType = data['machineType'];
          machineDetails = data;
        });
      } else {
        throw Exception(
            'Makine detayları alınamadı, Hata Kodu: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Makine detayları alınırken hata oluştu: $e'),
      ));
    }
  }

  Future<void> _editDetail(String key, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${languageProvider.selectedLanguage == 'Türkçe' ? 'Düzenle' : 'Edit'} $key',
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Yeni değeri girin'
                  : 'Enter new value',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'İptal' : 'Cancel',
              ),
            ),
            TextButton(
              onPressed: () async {
                String? token = await storage.read(key: 'token');
                String newValue = controller.text;

                // Kontroller
                if (widget.machineID.isNaN ||
                    key.isEmpty ||
                    newValue.isEmpty ||
                    token == null) {
                  print('Error: One of the values is empty or token is missing.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.selectedLanguage == 'Türkçe'
                            ? 'Gerekli alanlar eksik veya token yok.'
                            : 'Required fields are missing or token is null.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  final url = Uri.parse(
                      'https://ondergrup.hidirektor.com.tr/api/v2/machine/updateMachine');
                  final response = await http.put(
                    url,
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: json.encode({
                      'machineID': widget.machineID,
                      'updateData': [
                        {
                          key: newValue,
                        },
                      ],
                    }),
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      machineDetails[key] = newValue;
                    });
                    Navigator.of(context).pop();
                  } else {
                    print('Failed to update machine: ${response.statusCode}');
                    print('Response body: ${response.body}');
                    throw Exception('Failed to update machine: ${response.statusCode}');
                  }
                } catch (e) {
                  print('Error updating machine: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.selectedLanguage == 'Türkçe'
                            ? 'Makine güncellenemedi: $e'
                            : 'Failed to update machine: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'Kaydet' : 'Save',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // LanguageProvider'ı dinamik dil değişikliği için ekliyoruz
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.selectedLanguage == 'Türkçe' ? 'Makine' : 'Machine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: machineDetails.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              machineName,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              machineType,
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              height: 60.0,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HataScreen(machineID: widget.machineID.toString()),
                          ),
                        );
                      },
                      child: Container(
                        color: const Color(0xFFBE1522),
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: ListTile(
                            title: Text(
                              languageProvider.selectedLanguage == 'Türkçe'
                                  ? 'Makine Hata Kaydı'
                                  : 'Machine Error Log',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BakimScreen(machineID: widget.machineID.toString()),
                          ),
                        );
                      },
                      child: Container(
                        color: const Color(0xFF222F5A),
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: ListTile(
                            title: Text(
                              languageProvider.selectedLanguage == 'Türkçe'
                                  ? 'Makine Bakım Kaydı'
                                  : 'Machine Maintenance Log',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: ListView(
                children: machineDetails.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    subtitle: Text(entry.value.toString()),
                    trailing: (role == 'engineer' || role == 'sysop') &&
                        !(role == 'engineer' && entry.key == 'ownerUser')
                        ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editDetail(entry.key, entry.value.toString());
                      },
                    )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

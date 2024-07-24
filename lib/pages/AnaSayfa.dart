import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'bakim.dart';
import 'hata.dart';

String getCurrentDatetimeForMysql() {
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}


class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class MachineListScreen extends StatefulWidget {
  final String id;

  MachineListScreen({required this.id});

  @override
  _MachineListScreenState createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Makineleri Seçin'),
      ),
      body: FutureBuilder(
        future: fetchMachines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final machines = snapshot.data as List<dynamic>;

          return ListView.builder(
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              final machineType = machine['machineType'] ?? 'Unknown Type';
              final machineId = machine['machineID'] ?? 'Unknown ID';

              return Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.precision_manufacturing),
                    title: Text(
                      machine['machineName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Machine Type: $machineType',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Machine ID: $machineId',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      int id = int.tryParse(widget.id) ?? -1; // `id` değerini int'e dönüştür
                      switch (id) {
                        case 0:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BakimPopUp(machineID: machine['machineID']),
                            ),
                          );
                          break;
                        case 1:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BakimScreen(machineID: machine['machineID']),
                            ),
                          );
                          break;
                        case 2:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HataScreen(machineID: machine['machineID']),
                            ),
                          );
                          break;
                        default:
                          print('Unknown id: $id'); // Tanımlı olmayan id'ler için hata mesajı
                      }
                    },
                  ),
                  Divider(), // Adds a horizontal line between items
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<dynamic>> fetchMachines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    try {
      final url = Uri.parse('http://10.0.2.2:3000/api/machines/list'); // Express.js server adresine göre güncelleyin
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Token'ı Authorization başlığına ekleyin
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load machines');
      }
    } catch (e) {
      print('Error fetching machines: $e');
      throw Exception('Error occurred while fetching machines: $e');
    }
  }
}

class BakimPopUp extends StatefulWidget {
  final String machineID;

  BakimPopUp({required this.machineID});

  @override
  _BakimPopUpState createState() => _BakimPopUpState();
}

class _BakimPopUpState extends State<BakimPopUp> {
  TextEditingController maintenanceIdController = TextEditingController();
  TextEditingController maintenanceDateController = TextEditingController();
  List<TextEditingController> noteControllers = List.generate(10, (index) => TextEditingController());
  List<String> maintenanceStatuses = List.generate(36, (index) => "1");
  int? selectedState;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addMaintenanceToDatabase() async {
    // Otomatik tarihi al ve formatla
    print(noteControllers);
    String formattedDate = getCurrentDatetimeForMysql();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    // JSON yapısını oluşturun
    Map<String, dynamic> data = {
      'machineID': widget.machineID,
      'maintenanceId': maintenanceIdController.text,
      'maintenanceDate': formattedDate, // Otomatik tarih kullanılıyor
      'maintenanceStatuses': maintenanceStatuses,
      'notes': noteControllers.map((controller) => controller.text).toList(),
    };

    final Uri uri = Uri.parse('http://10.0.2.2:3000/api/maintenance/add');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // İçerik türü başlığı ekleniyor
        },
        body: json.encode(data), // JSON yapısını body'ye ekleyin
      );

      print(response.statusCode);
      if (response.statusCode == 201) {
        print('Maintenance added successfully!');
        Navigator.of(context).pop(); // Dialog'u kapatın
      } else {
        print('Error adding maintenance: ${response.body}');
      }
    } catch (e) {
      print('Error adding maintenance: $e');
    }
  }

  void showAddMaintenancesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Bakım Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maintenanceIdController,
                decoration: InputDecoration(hintText: 'Bakım ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                addMaintenanceToDatabase();
              },
              child: Text('Ekle'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bakım Kaydı Oluştur'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            children: [
              buildButtonGrid(),
              if (selectedState != null)
                fillTableWithData(selectedState!, getDataForState(selectedState!)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(26.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFBE1522), // Button background color
          ),
          onPressed: () {
            showAddMaintenancesDialog();
          },
          child: Text(
            'Create Maintenance Log',
            style: TextStyle(color: Colors.white), // Button text color
          ),
        ),
      ),
    );
  }

  Widget buildButtonGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSectionButton('Fonksiyonlar ve Kontrol', 1),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Platform Montaj', 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Makaslar', 3),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: buildSectionButton('Genel', 4),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Hidrolik', 5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Elektrik', 6),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: buildSectionButton('Kılavuz ve Etiket', 7),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Şase', 8),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton('Açıklama Notu', 9),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSectionButton(String title, int section) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF222F5A), // Button color
      ),
      onPressed: () {
        setState(() {
          selectedState = section;
        });
      },
      child: Text(
        title,
        textAlign: TextAlign.center, // Center the text
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget fillTableWithData(int section, List<String> data) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Section $section',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222F5A),
            ),
          ),
        ),
        Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          border: TableBorder.all(
            color: Colors.grey,
          ),
          children: List<TableRow>.generate(
            data.length,
                (index) {
              if (section < 9) {
                int calculatedIndex = (section - 1) * 4 + index;
                if (calculatedIndex < maintenanceStatuses.length) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            data[index],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Center(
                          child: DropdownButton<String>(
                            value: maintenanceStatuses[calculatedIndex],
                            items: [
                              DropdownMenuItem(
                                value: "1",
                                child: Text("Tamam"),
                              ),
                              DropdownMenuItem(
                                value: "2",
                                child: Text("Hatalı"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                maintenanceStatuses[calculatedIndex] = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Index out of bounds, handle accordingly.
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Invalid index',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Center(
                          child: Text(
                            'Invalid',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              } else if (section == 9) {
                // Note section
                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          data[index],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: TextField(
                          controller: noteControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Not Girin',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Invalid section',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Text(
                          'Invalid',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  List<String> getDataForState(int state) {
    switch (state) {
      case 1:
        return [
          'Fonksiyonlar ve Kontrol 1',
          'Fonksiyonlar ve Kontrol 2',
          'Fonksiyonlar ve Kontrol 3',
          'Fonksiyonlar ve Kontrol 4',
        ];
      case 2:
        return [
          'Platform Montaj 1',
          'Platform Montaj 2',
          'Platform Montaj 3',
          'Platform Montaj 4',
        ];
      case 3:
        return [
          'Makaslar 1',
          'Makaslar 2',
          'Makaslar 3',
          'Makaslar 4',
          'Makaslar 5',
          'Makaslar 6',
        ];
      case 4:
        return [
          'Genel 1',
          'Genel 2',
          'Genel 3',
          'Genel 4',
          'Genel 5',
          'Genel 6',
        ];
      case 5:
        return [
          'Hidrolik 1',
          'Hidrolik 2',
          'Hidrolik 3',
          'Hidrolik 4',
          'Hidrolik 5',
          'Hidrolik 6',
        ];
      case 6:
        return [
          'Elektrik 1',
          'Elektrik 2',
          'Elektrik 3',
        ];
      case 7:
        return [
          'Kılavuz ve Etiket 1',
          'Kılavuz ve Etiket 2',
        ];
      case 8:
        return [
          "Şase 1",
          'Şase 2',
          'Şase 3',
        ];
      case 9:
        return [
          'Not 1',
          'Not 2',
          'Not 3',
          'Not 4',
          'Not 5',
          'Not 6',
          'Not 7',
          'Not 8',
          'Not 9',
          'Not 10',
        ];
      default:
        return [];
    }
  }
}

class MakinePopUp extends StatefulWidget {
  @override
  _MakinePopUpState createState() => _MakinePopUpState();
}

class _MakinePopUpState extends State<MakinePopUp> {
  String? _selectedMachineType;
  TextEditingController _machineIdController = TextEditingController();
  TextEditingController _machineNameController = TextEditingController();
  String name = '';

  @override
  void initState() {
    super.initState();
  }

  Future<String> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token bulunamadı');
    }

    final url = Uri.parse('http://10.0.2.2:3000/api/users/list');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> userDataList = json.decode(response.body);
      print(userDataList);

      if (userDataList.isNotEmpty && userDataList[0] is Map<String, dynamic>) {
        final userData = userDataList[0];
        if (userData['username'] is String) {
          return userData['username'];
        } else {
          throw Exception('Geçersiz kullanıcı verisi');
        }
      } else {
        throw Exception('Kullanıcı verisi bulunamadı');
      }
    } else {
      throw Exception('Kullanıcı profili alınamadı: ${response.statusCode}');
    }
  }

  Future<void> _addMachine() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen oturum açın.')),
        );
        return;
      }

      String username = await _getUsername();
      print(username);
      print(_machineIdController.text);
      print(_machineNameController.text);
      print(_selectedMachineType);
      final url = Uri.parse('http://10.0.2.2:3000/api/machines/add');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'machineID': int.parse(_machineIdController.text),
          'machineName': _machineNameController.text,
          'machineType': _selectedMachineType,
          'ownerUser': username,
        }),
      );
      print('HTTP Yanıt Kodu: ${response.statusCode}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Makine başarıyla eklendi.')),
        );
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception('Makine ekleme başarısız oldu: ${errorResponse['error']}');
      }
    } catch (e) {
      print('Error adding machine: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Makine ekleme hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Makine Ekle',
        style: TextStyle(
          fontSize: 20, // Yazı boyutu
          color: Color(0xFF222F5A), // Yazı rengi
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Makine Adı:'),
          TextFormField(
            controller: _machineNameController,
            decoration: InputDecoration(
              hintText: 'Makine Adı girin',
            ),
          ),
          Text('Makine Türü:'),
          DropdownButton<String>(
            value: _selectedMachineType,
            items: ['ESP', 'CSP'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedMachineType = value;
              });
            },
            isExpanded: true,
            hint: Text('Seçiniz'),
          ),
          SizedBox(height: 10), // Boşluk ekleyin
          Text('Makine ID:'),
          TextFormField(
            controller: _machineIdController,
            decoration: InputDecoration(
              hintText: 'Makine ID girin',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _addMachine,
          child: Text(
            'Ekle',
            style: TextStyle(
              fontSize: 18, // Yazı boyutu
              color: Color(0xFF222F5A), // Yazı rengi
            ),
          ),
        ),
      ],
    );
  }
}

class _AnaSayfaState extends State<AnaSayfa> {
  late String _username = '';
  late String _name = '';
  late String uid = '';
  late String role = '';
  String mail = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return;
    }

    bool tokenGecerli = await _validateToken(token);
    print(tokenGecerli);
    if (!tokenGecerli) {
      // Token'ı yenile
      await _refreshToken();
      // Güncellenmiş token'ı al
      token = prefs.getString('token');
    }
    getUserRole();
  }

  Future<bool> _validateToken(String token) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/auth/validateToken');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      // Token geçerli ise true döndür
      return true;
    } else {
      // Token geçerli değilse veya hata oluştuysa false döndür
      return false;
    }
  }

  Future<void> _refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('token');

    if (oldToken == null) {
      throw Exception('Old token not found');
    }

    final url = Uri.parse('http://10.0.2.2:3000/api/auth/refreshToken');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldToken': oldToken,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // JSON yanıtını parsel
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Yanıtı yazdırarak kontrol et
      print('Response data: $responseData');

      // İç içe geçmiş token'ı al
      final newToken = responseData['token']['token'];

      if (newToken is String) {
        // Yeni token'ı SharedPreferences'e kaydet
        await prefs.setString('token', newToken);
      } else {
        throw Exception('Invalid token format');
      }
    } else {
      throw Exception('Token refresh failed');
    }
  }

  Future<void> getUserRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('email') ?? '';
      String token = prefs.getString('token') ?? '';

      print('Retrieved email: $email and token: $token');

      final url = Uri.parse('http://10.0.2.2:3000/api/users/getRole?email=$email');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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

  @override
  void initState() {
    super.initState();
    _handleToken();
  }

  String _getRoleBasedText() {
    switch (role) {
      case 'guest':
        return 'Makine Ekle';
      case 'engineer':
        return 'Bakım Kaydı Ekle';
      case 'technician':
        return 'Makine Ekle';
      case 'sysop':
        return 'Kullanıcı Ekle';
      default:
        return '';
    }
  }

  void _goScreenFromRole() {
    switch (role) {
      case 'guest':
      case 'sysop':
      case 'technician':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return MakinePopUp(); // Özelleştirilmiş pop-up gösterilsin
          },
        );
        break;
      case 'engineer':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return MachineListScreen(id: '0',); // Özelleştirilmiş pop-up gösterilsin
          },
        );
        break;
      default:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Hata'),
              content: Text('Geçersiz rol'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tamam'),
                ),
              ],
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(''),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 850.0,
              maxWidth: 850.0,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _goScreenFromRole,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _getRoleBasedText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment(0, -0.44),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.save),
                        onPressed: () {
                          Navigator.pushNamed(context, "/makineler");
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment(0, -0.28),
                  child: Text(
                    'Kayıtlı Makineler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _username.isNotEmpty
                            ? 'Merhaba, $_name'
                            : 'Merhaba, Kullanıcı',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profil',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/profil");
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bakım Geçmişi',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return MachineListScreen(id: '1',); // Özelleştirilmiş pop-up gösterilsin
                    },
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hata Kayıtları',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return MachineListScreen(id: '2',); // Özelleştirilmiş pop-up gösterilsin
                    },
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Belgeler',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/belge");
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ayarlar',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/ayar");
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        color: Color(0xFFBE1522),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  } catch (e) {
                    print('Error navigating: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
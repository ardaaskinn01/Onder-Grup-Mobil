import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

String getCurrentDatetimeForMysql() {
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}


class AnaSayfa extends StatefulWidget {
  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}


class MachineListScreen extends StatelessWidget {
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BakimPopUp(machineID: machine['machineID']),
                        ),
                      );
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
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/getMachines'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load machines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load machines: $e');
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
  List<String> notes = List.generate(10, (index) => "");

  @override
  void initState() {
    super.initState();
    loadMaintenanceData();
  }

  Future<void> loadMaintenanceData() async {
    final Uri uri = Uri.parse('http://10.0.2.2:3000/getMaintenanceData?machineID=${widget.machineID}&maintenanceId=${maintenanceIdController.text}');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          List<dynamic> kontroller = data['kontroller'] ?? [];
          for (int i = 0; i < maintenanceStatuses.length; i++) {
            if (i < kontroller.length) {
              maintenanceStatuses[i] = kontroller[i];
            }
          }

          List<dynamic> notesData = data['notes'] ?? [];
          for (int i = 0; i < noteControllers.length; i++) {
            if (i < notesData.length) {
              noteControllers[i].text = notesData[i];
            }
          }

          String? maintenanceDate = data['maintenanceDate'];
          if (maintenanceDate != null) {
            maintenanceDateController.text = maintenanceDate;
          }
        });
      } else {
        print('Error loading maintenance data: ${response.body}');
      }
    } catch (e) {
      print('Error loading maintenance data: $e');
    }
  }

  Future<void> addMaintenanceToDatabase() async {
    // Otomatik tarihi al ve formatla
    String formattedDate = getCurrentDatetimeForMysql();

    // JSON yapısını oluşturun
    Map<String, dynamic> data = {
      'machineID': widget.machineID,
      'maintenanceId': maintenanceIdController.text,
      'maintenanceDate': formattedDate, // Otomatik tarih kullanılıyor
      'maintenanceStatuses': maintenanceStatuses,
      'notes': noteControllers.map((controller) => controller.text).toList(),
    };

    final Uri uri = Uri.parse('http://10.0.2.2:3000/addMaintenance');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
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
                (index) => TableRow(
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
                      value: maintenanceStatuses[(section - 1) * 4 + index],
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
                          maintenanceStatuses[(section - 1) * 4 + index] = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (section == 9) buildNoteSection(section),
      ],
    );
  }

  Widget buildNoteSection(int section) {
    return Column(
      children: List<Widget>.generate(
        10,
            (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: TextFormField(
            controller: noteControllers[index],
            onChanged: (value) {
              notes[index] = value;
            },
            decoration: InputDecoration(
              labelText: 'Not ${index + 1}',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
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

    final url = Uri.parse('http://10.0.2.2:3000/getUserProfile');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      return userData['username'];
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

      final url = Uri.parse('https://85.95.231.92:3000/addMachine');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ownerUser': username,
          'machineName': _machineNameController.text,
          'machineID': _machineIdController.text,
          'machineType': _selectedMachineType,
        }),
      );

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

  Future<String> getMail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      mail = prefs.getString('mail') ?? 'Unknown User';
    });
    return mail;
  }

  Future<void> getUserRole(String mail) async {
    final url = Uri.parse('http://10.0.2.2:3000/getRole?uid=$mail');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        role = data['role'];
      });
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize(); // Asenkron işlemleri başlat
  }

  // Asenkron işlemleri yapmak için bir yardımcı fonksiyon
  Future<void> _initialize() async {
    String mail = await getMail();
    await getUserRole(mail);
    setState(() {
      this.mail = mail; // Maili güncelle
    });
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
            return MachineListScreen(); // Özelleştirilmiş pop-up gösterilsin
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
                      return MachineListScreen(); // Özelleştirilmiş pop-up gösterilsin
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
                      return MachineListScreen(); // Özelleştirilmiş pop-up gösterilsin
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
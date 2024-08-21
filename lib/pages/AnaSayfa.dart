import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/pages/adminpanel.dart';
import 'package:onderliftmobil/pages/login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'languageprovider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'bakim.dart';
import 'hata.dart';

final storage = FlutterSecureStorage();

String getCurrentDatetimeForMysql() {
  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}

Future<String?> _getUsername() async {
  String? username = await storage.read(key: 'username');
  return username;
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.selectedLanguage == 'Türkçe'
              ? 'Makineleri Seçin'
              : 'Choose the Machine',
        ),
      ),
      body: FutureBuilder(
        future: fetchMachines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final machines = snapshot.data as List<dynamic>;

          if (machines.isEmpty) {
            return Center(
                child: Text(
              languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Veri Bulunamadı'
                  : 'Data has Not Found',
            ));
          }

          return ListView.builder(
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              final machineType = machine['machineType'] ?? 'Unknown Type';
              final machineId = machine['machineID'] ?? 'Unknown ID';

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing),
                    title: Text(
                      machine['machineName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${languageProvider.selectedLanguage == 'Türkçe' ? 'Makine Türü' : 'Machine Type'}: $machineType',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${languageProvider.selectedLanguage == 'Türkçe' ? "Makine ID'si" : 'Machine ID'}: $machineId',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      int id = int.tryParse(widget.id) ??
                          -1; // `id` değerini int'e dönüştür
                      switch (id) {
                        case 0:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BakimPopUp(
                                  machineID: machine['machineID'].toString()),
                            ),
                          );
                          break;
                        case 1:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BakimScreen(
                                  machineID: machine['machineID'].toString()),
                            ),
                          );
                          break;
                        case 2:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HataScreen(
                                  machineID: machine['machineID'].toString()),
                            ),
                          );
                          break;
                        default:
                        // Tanımlı olmayan id'ler için hata mesajı
                      }
                    },
                  ),
                  const Divider(), // Adds a horizontal line between items
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<dynamic>> fetchMachines() async {
    String? token = await storage.read(key: 'token');
    try {
      final url = Uri.parse(
          'https://ondergrup.hidirektor.com.tr/api/v2/authorized/getAllMachines'); // Express.js server adresine göre güncelleyin
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
  List<TextEditingController> noteControllers =
      List.generate(10, (index) => TextEditingController());
  List<String> maintenanceStatuses = List.generate(34, (index) => "1");
  List<List<String>> sectionMaintenanceStatuses = List.generate(8, (_) => List<String>.filled(34, '1'));
  int? selectedState;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addMaintenanceToDatabase() async {
    // Otomatik tarihi al ve formatla
    String formattedDate = getCurrentDatetimeForMysql();
    String? token = await storage.read(key: 'token');
    // JSON yapısını oluşturun
    Map<String, dynamic> data = {
      'machineID': widget.machineID,
      'maintenanceStatuses': maintenanceStatuses,
      'notes': noteControllers.map((controller) => controller.text).toList(),
    };

    final Uri uri =
        Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/createMaintenance');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // İçerik türü başlığı ekleniyor
      },
      body: json.encode(data), // JSON yapısını body'ye ekleyin
    );

    if (response.statusCode == 201) {
      Navigator.of(context).pop(); // Dialog'u kapatın
    } else {}
  }

  void showAddMaintenancesDialog() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Yeni Bakım Ekle'
                : 'Add New Maintenance',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maintenanceIdController,
                decoration: InputDecoration(
                  hintText: languageProvider.selectedLanguage == 'Türkçe'
                      ? "Bakım ID'si"
                      : 'Maintenance ID',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                addMaintenanceToDatabase();
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'Ekle' : 'Add',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.selectedLanguage == 'Türkçe'
              ? 'Bakım Kaydı Oluştur'
              : 'Create Maintenance Log',
        ),
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
                fillTableWithData(
                    selectedState!, getDataForState(selectedState!)),
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
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Bakım Kaydı Oluştur'
                : 'Create Maintenance Log',
            style: TextStyle(color: Colors.white), // Button text color
          ),
        ),
      ),
    );
  }

  Widget buildButtonGrid() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Fonksiyonlar ve Kontrol'
                      : 'Functions and Control',
                  1),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Platform ve Montaj'
                      : 'Platform and Assembly',
                  2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Makaslar'
                      : 'Scissors',
                  3),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Genel'
                      : 'General',
                  4),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Hidrolik'
                      : 'Hydrolic',
                  5),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Elektrik'
                      : 'Electricity',
                  6),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Kılavuz ve Etiket'
                      : 'Guideline and Label',
                  7),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Şase'
                      : 'Chassis',
                  8),
            ),
            SizedBox(width: 8),
            Expanded(
              child: buildSectionButton(
                  languageProvider.selectedLanguage == 'Türkçe'
                      ? 'Açıklama Notu'
                      : 'Explanatory Note ',
                  9),
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '${languageProvider.getLocalizedString('category')} $section',
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
                  if (section == 9) {
                    // Eğer section 9 ise, not girişi için TextField döndür
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
                                hintText: languageProvider.getLocalizedString('enterNote'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Diğer sectionlar için index hesaplaması
                    int baseIndex = 0;

                    // Sectiona göre baseIndex hesaplama
                    if (section == 1) baseIndex = 0;
                    else if (section == 2) baseIndex = 4;
                    else if (section == 3) baseIndex = 8;
                    else if (section == 4) baseIndex = 14;
                    else if (section == 5) baseIndex = 20;
                    else if (section == 6) baseIndex = 26;
                    else if (section == 7) baseIndex = 29;
                    else if (section == 8) baseIndex = 31;

                    int calculatedIndex = baseIndex + index;

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
                                    child: Text(languageProvider.getLocalizedString('complete')),
                                  ),
                                  DropdownMenuItem(
                                    value: "2",
                                    child: Text(languageProvider.getLocalizedString('faulty')),
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
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                languageProvider.getLocalizedString('invalidIndex'),
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
                                languageProvider.getLocalizedString('invalid'),
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> getDataForState(int state) {
    // Dil seçimine göre veri listeleri
    final languageProvider = Provider.of<LanguageProvider>(context);
    final turkishData = {
      1: [
        'Fonksiyonlar ve Kontrol 1',
        'Fonksiyonlar ve Kontrol 2',
        'Fonksiyonlar ve Kontrol 3',
        'Fonksiyonlar ve Kontrol 4',
      ],
      2: [
        'Platform Montaj 1',
        'Platform Montaj 2',
        'Platform Montaj 3',
        'Platform Montaj 4',
      ],
      3: [
        'Makaslar 1',
        'Makaslar 2',
        'Makaslar 3',
        'Makaslar 4',
        'Makaslar 5',
        'Makaslar 6',
      ],
      4: [
        'Genel 1',
        'Genel 2',
        'Genel 3',
        'Genel 4',
        'Genel 5',
        'Genel 6',
      ],
      5: [
        'Hidrolik 1',
        'Hidrolik 2',
        'Hidrolik 3',
        'Hidrolik 4',
        'Hidrolik 5',
        'Hidrolik 6',
      ],
      6: [
        'Elektrik 1',
        'Elektrik 2',
        'Elektrik 3',
      ],
      7: [
        'Kılavuz ve Etiket 1',
        'Kılavuz ve Etiket 2',
      ],
      8: [
        'Şase 1',
        'Şase 2',
        'Şase 3',
      ],
      9: [
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
      ],
    };

    final englishData = {
      1: [
        'Functions and Control 1',
        'Functions and Control 2',
        'Functions and Control 3',
        'Functions and Control 4',
      ],
      2: [
        'Platform Assembly 1',
        'Platform Assembly 2',
        'Platform Assembly 3',
        'Platform Assembly 4',
      ],
      3: [
        'Scissors 1',
        'Scissors 2',
        'Scissors 3',
        'Scissors 4',
        'Scissors 5',
        'Scissors 6',
      ],
      4: [
        'General 1',
        'General 2',
        'General 3',
        'General 4',
        'General 5',
        'General 6',
      ],
      5: [
        'Hydraulic 1',
        'Hydraulic 2',
        'Hydraulic 3',
        'Hydraulic 4',
        'Hydraulic 5',
        'Hydraulic 6',
      ],
      6: [
        'Electric 1',
        'Electric 2',
        'Electric 3',
      ],
      7: [
        'Guide and Label 1',
        'Guide and Label 2',
      ],
      8: [
        'Chassis 1',
        'Chassis 2',
        'Chassis 3',
      ],
      9: [
        'Note 1',
        'Note 2',
        'Note 3',
        'Note 4',
        'Note 5',
        'Note 6',
        'Note 7',
        'Note 8',
        'Note 9',
        'Note 10',
      ],
    };

    // Dil seçimine göre uygun listeyi döndür
    if (languageProvider.selectedLanguage == 'Türkçe') {
      return turkishData[state] ?? [];
    } else {
      return englishData[state] ?? [];
    }
  }
}

class MakinePopUp extends StatefulWidget {
  @override
  _MakinePopUpState createState() => _MakinePopUpState();
}

class _MakinePopUpState extends State<MakinePopUp> {
  String? _selectedMachineType;
  final TextEditingController _machineIdController = TextEditingController();
  final TextEditingController _machineNameController = TextEditingController();
  String name = '';
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void dispose() {
    controller?.stopCamera();
    controller?.dispose();
    _machineNameController.dispose();
    _machineIdController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    setState(() {
      controller = qrController;
    });
    controller!.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (result != null) {
          _machineNameController.text = result!.code!;
          _machineIdController.text = result!.code!;
        }
      });
    });
  }

  Future<void> _addMachine() async {
    final languageProvider = Provider.of<LanguageProvider>(context);
    try {
      String? token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Lütfen Oturum Açın'
                : 'Please Sign in',
          )),
        );
        return;
      }

      String? userName = await _getUsername();
      final url = Uri.parse('http://85.95.231.92:3001/api/machines/addMachine');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'machineID': (_machineIdController.text),
          'machineName': _machineNameController.text,
          'machineType': _selectedMachineType,
          'ownerUser': userName,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Makine Başarıyla Eklendi'
                : 'The Machine has Added Successfully',
          )),
        );
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            'Makine ekleme başarısız oldu: ${errorResponse['error']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${languageProvider.selectedLanguage == 'Türkçe' ? 'Makine Ekleme Hatası' : 'Error Adding Machine'}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AlertDialog(
      title: Text(
        languageProvider.selectedLanguage == 'Türkçe'
            ? 'Makine Ekle'
            : 'Add Machine',
        style: TextStyle(
          fontSize: 20,
          color: Color(0xFF222F5A),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(languageProvider.selectedLanguage == 'Türkçe'
              ? 'Makine Adı:'
              : 'Machine Name:'),
          TextFormField(
            controller: _machineNameController,
            decoration: InputDecoration(
              hintText: languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Makine Adı girin'
                  : 'Enter Machine Name',
            ),
          ),
          Text(languageProvider.selectedLanguage == 'Türkçe'
              ? 'Makine Türü:'
              : 'Machine Type:'),
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
            hint: Text(languageProvider.selectedLanguage == 'Türkçe'
                ? 'Seçiniz'
                : 'Select'),
          ),
          SizedBox(height: 10),
          Text(languageProvider.selectedLanguage == 'Türkçe'
              ? 'Makine ID:'
              : 'Machine ID:'),
          TextFormField(
            controller: _machineIdController,
            decoration: InputDecoration(
              hintText: languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Makine ID girin'
                  : 'Enter Machine ID',
            ),
          ),
          SizedBox(height: 10),
          IconButton(
            icon: Icon(Icons.qr_code),
            iconSize: 30.0, // İkonun boyutunu ayarlayabilirsiniz
            color: Colors.black, // İkonun rengini ayarlayabilirsiniz
            onPressed: () => _showQRScanner(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _addMachine,
          child: Text(
            languageProvider.selectedLanguage == 'Türkçe' ? 'Ekle' : 'Add',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF222F5A),
            ),
          ),
        ),
      ],
    );
  }

  void _showQRScanner(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'QR Kod Tarayıcı'
                : 'QR Code Scanner',
          ),
          content: Container(
            width: 300,
            height: 300,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller?.stopCamera();
                Navigator.of(context).pop();
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'Kapat'
                    : 'Close',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnaSayfaState extends State<AnaSayfa> {
  late String _username = '';
  late String uid = '';
  late String role = '';
  String mail = '';
  bool _isSubUser = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _changeLanguage(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Dil Seçin'
                : 'Choose the Language',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Türkçe'),
                leading: Radio<String>(
                  value: 'Türkçe',
                  groupValue: languageProvider.selectedLanguage,
                  onChanged: (String? value) {
                    languageProvider.changeLanguage(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: Text('İngilizce'),
                leading: Radio<String>(
                  value: 'İngilizce',
                  groupValue: languageProvider.selectedLanguage,
                  onChanged: (String? value) {
                    languageProvider.changeLanguage(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
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

  Future<void> _handleToken() async {
    String? token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }

    bool tokenGecerli = await _validateToken(token);
    if (!tokenGecerli) {
      // Token'ı yenile
      await _refreshToken();
      // Güncellenmiş token'ı al
      token = await storage.read(key: 'token');
    }
    getUserRole();
  }

  Future<bool> _validateToken(String token) async {
    final url = Uri.parse('http://85.95.231.92:3001/api/token/validateToken');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      // Token geçerli ise true döndür
      return true;
    } else {
      // Token geçerli değilse veya hata oluştuysa false döndür
      return false;
    }
  }

  Future<void> _refreshToken() async {
    String? oldToken = await storage.read(key: 'token');

    if (oldToken == null) {
      throw Exception('Old token not found');
    }

    final url = Uri.parse('http://85.95.231.92:3001/api/token/refreshToken');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldToken': oldToken,
      }),
    );

    if (response.statusCode == 200) {
      // JSON yanıtını parsel
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Yanıtı yazdırarak kontrol et

      // İç içe geçmiş token'ı al
      final newToken = responseData['token']['token'];

      if (newToken is String) {
        // Yeni token'ı SharedPreferences'e kaydet
        await storage.write(key: 'token', value: newToken);
      } else {
        throw Exception('Invalid token format');
      }
    } else {
      throw Exception('Token refresh failed');
    }
  }

  Future<void> getUserRole() async {
    try {
      String? username = await storage.read(key: 'username');
      String? token = await storage.read(key: 'token');
      _username = (await _getUsername())!;

      final url = Uri.parse(
          'http://85.95.231.92:3001/api/users/getRole?username=$username');
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
      } else {}
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _handleToken();
    _checkUserRole();
  }

  String _getRoleBasedText(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    switch (role) {
      case 'guest':
      case 'engineer':
        return languageProvider.selectedLanguage == 'Türkçe'
            ? 'Makine Ekle'
            : 'Add Machine';
      case 'technician':
        return languageProvider.selectedLanguage == 'Türkçe'
            ? 'Bakım Kaydı Ekle'
            : 'Add Maintenance Record';
      case 'sysop':
        return languageProvider.selectedLanguage == 'Türkçe'
            ? 'Kullanıcı Kayıtları'
            : 'User Records';
      default:
        return '';
    }
  }

  void _goScreenFromRole(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    switch (role) {
      case 'guest':
      case 'engineer':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return MakinePopUp(); // Özelleştirilmiş pop-up gösterilsin
          },
        );
        break;
      case 'technician':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return MachineListScreen(
                id: '0'); // Özelleştirilmiş pop-up gösterilsin
          },
        );
        break;
      case 'sysop':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AdminScreen(); // Özelleştirilmiş pop-up gösterilsin
          },
        );
        break;
      default:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'Hata'
                    : 'Error',
              ),
              content: Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'Geçersiz rol'
                    : 'Invalid role',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Tamam'
                        : 'OK',
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  Future<bool> logout() async {
    String? token = await storage.read(key: 'token');
    final url = Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/auth/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Logout başarısız
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkUserRole() async {
    String? token = await storage.read(key: 'token');

    if (token != null) {
      final payload = _decodeJwt(token);
      setState(() {
        _isSubUser = payload['isSubUser'] ?? false;
      });
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token');
      }

      // Helper function to add padding if necessary
      String addPadding(String base64String) {
        final missingPadding = (4 - (base64String.length % 4)) % 4;
        return base64String + '=' * missingPadding;
      }

      // Decode payload part
      final payload = base64Url.decode(
          addPadding(parts[1].replaceAll('-', '+').replaceAll('_', '/')));

      return jsonDecode(utf8.decode(payload));
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
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
          actions: [
            TextButton.icon(
              icon: Icon(
                Icons.language,
                color: Colors.black,
              ),
              label: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'Dil' : 'Language',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => _changeLanguage(context),
            ),
          ],
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
                        onPressed: () => _goScreenFromRole(
                            context), // context'i burada geçiyoruz
                      ),
                      SizedBox(height: 10),
                      Text(
                        _getRoleBasedText(
                            context), // context'i burada geçiyoruz
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
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
                    languageProvider.selectedLanguage == 'Türkçe'
                        ? 'Kayıtlı Makineler'
                        : 'Registered Machines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(0, 0.5),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.supervised_user_circle),
                        onPressed: _isSubUser
                            ? null
                            : () {
                                Navigator.pushNamed(context, "/sub");
                              },
                      ),
                    ],
                  ),
                ),
                _isSubUser
                    ? SizedBox.shrink()
                    : Align(
                        alignment: Alignment(0, 0.6),
                        child: Text(
                          languageProvider.selectedLanguage == 'Türkçe'
                              ? 'Alt Kullanıcılar'
                              : 'Sub Users',
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
                            ? '${languageProvider.getLocalizedString('greeting')}$_username'
                            : '${languageProvider.getLocalizedString('greeting')}Kullanıcı',
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
                      languageProvider.getLocalizedString('profile'),
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
                  if (!_isSubUser) {
                    Navigator.pushNamed(context, "/profil");
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.getLocalizedString('maintenanceHistory'),
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
                      return MachineListScreen(
                        id: '1',
                      );
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
                      languageProvider.getLocalizedString('errorRecords'),
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
                      return MachineListScreen(
                        id: '2',
                      );
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
                      languageProvider.getLocalizedString('documents'),
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
                      languageProvider.getLocalizedString('settings'),
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
                      languageProvider.getLocalizedString('logout'),
                      style: TextStyle(
                        color: Color(0xFFBE1522),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  try {
                    bool success = await logout();
                    if (success) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    }
                  } catch (e) {}
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

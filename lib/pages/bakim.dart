import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onderliftmobil/bakimvariables.dart';
import 'package:provider/provider.dart';
import 'languageprovider.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class BakimScreen extends StatefulWidget {
  final String machineID;

  BakimScreen({required this.machineID});

  @override
  _BakimScreenState createState() => _BakimScreenState();
}

class _BakimScreenState extends State<BakimScreen> {
  late Future<List<dynamic>> _maintenanceRecords;
  late String role = '';

  @override
  void initState() {
    super.initState();
    _maintenanceRecords = getMaintenanceRecords(widget.machineID);
  }

  Future<List<dynamic>> getMaintenanceRecords(String machineID) async {
    String? token = await storage.read(key: 'token');

    try {
      final url = Uri.parse(
          'http://85.95.231.92:3001/api/machines/getMaintenances?machineID=$machineID');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to load maintenance records');
      }
    } catch (e) {
      throw Exception('Error occurred while fetching maintenance records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.selectedLanguage == 'Türkçe'
              ? 'Bakım Kayıtları'
              : 'Maintenance Logs',
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _maintenanceRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Bakım Kaydı Bulunamadı'
                  : 'Maintenance Log Not Found',
            ));
          }

          final maintenanceRecords = snapshot.data!;

          return ListView.separated(
            itemCount: maintenanceRecords.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final record = maintenanceRecords[index];
              return ListTile(
                leading: Icon(
                  Icons.build,
                  color: Color(0xFFBE1522),
                  size: 30.0,
                ),
                title: Text(
                  '${languageProvider.getLocalizedString('idLabel')}: ${record['id'].toString()}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${languageProvider.getLocalizedString('maintenanceDateLabel')}: ${record['maintenanceDate']}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.0,
                  color: Colors.grey,
                ),
                tileColor: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MaintenanceDetailScreen(record: record),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class MaintenanceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  MaintenanceDetailScreen({required this.record});

  String categorizeControl(int index) {
    if (index >= 0 && index <= 3) {
      return "Fonksiyonlar ve Kontrol";
    } else if (index >= 4 && index <= 7) {
      return "Platform Montaj";
    } else if (index >= 8 && index <= 13) {
      return "Makaslar";
    } else if (index >= 14 && index <= 19) {
      return "Genel";
    } else if (index >= 20 && index <= 25) {
      return "Hidrolik";
    } else if (index >= 26 && index <= 28) {
      return "Elektrik";
    } else if (index >= 29 && index <= 30) {
      return "Kılavuz ve Etiket";
    } else if (index >= 31 && index <= 33) {
      return "Şase";
    } else {
      return "Bilinmeyen Kategori";
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getLocalizedString('maintenanceDetails')),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailCard(
              icon: Icons.perm_identity,
              title: languageProvider.getLocalizedString('maintenanceID'),
              content: record['id'].toString(),
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.calendar_today,
              title: languageProvider.getLocalizedString('maintenanceDate'),
              content: record['maintenanceDate'].toString(),
            ),
            SizedBox(height: 16.0),
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                String result =
                    _buildControlCategories(record, languageProvider);

                return _buildDetailCard(
                  icon: Icons.check_circle,
                  title: languageProvider.getLocalizedString('controls'),
                  content:
                      result, // Burada `result` bir `String` olarak geçiyor
                );
              },
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.note,
              title: languageProvider.getLocalizedString('notes'),
              content: _buildNotes(record),
            ),
            SizedBox(height: 16.0),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BakimPopUp(
                            maintenanceID: record['id'].toString(),
                            machineID: record['machineID'].toString(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF222F5A),
                    ),
                    child: Text(
                      languageProvider.getLocalizedString('edit'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0), // Butonlar arasında boşluk
                  ElevatedButton(
                    onPressed: () {
                      deleteMaintenanceFromDatabase(
                        maintenanceID: record['id'],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBE1522),
                    ),
                    child: Text(
                      languageProvider.getLocalizedString('delete'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildControlCategories(
      Map<String, dynamic> record, LanguageProvider languageProvider) {
    List<String> categorizedControls = [];

    // Kontrol anahtarları listesi
    List<String> kontrolKeys = [
      'kontrol11', 'kontrol12', 'kontrol13', 'kontrol14', // 11-14
      'kontrol21', 'kontrol22', 'kontrol23', 'kontrol24', // 21-24
      'kontrol31', 'kontrol32', 'kontrol33', 'kontrol34', 'kontrol35',
      'kontrol36', // 31-36
      'kontrol41', 'kontrol42', 'kontrol43', 'kontrol44', 'kontrol45',
      'kontrol46', // 41-46
      'kontrol51', 'kontrol52', 'kontrol53', 'kontrol54', 'kontrol55',
      'kontrol56', // 51-56
      'kontrol61', 'kontrol62', 'kontrol63', // 61-63
      'kontrol71', 'kontrol72', // 71-72
      'kontrol81', 'kontrol82', 'kontrol83', // 81-83
    ];

    final faultyText =
        languageProvider.getLocalizedString('faulty'); // Hatalı metni al

    for (int i = 0; i < kontrolKeys.length; i++) {
      String key = kontrolKeys[i];
      if (record[key] == '2') {
        String category = categorizeControl(i);
        categorizedControls.add("$category [$faultyText]");
      }
    }

    return categorizedControls.join("\n"); // Tek bir String'e dönüştürüyoruz
  }

  // Notları filtreleyip birleştirme
  String _buildNotes(Map<String, dynamic> record) {
    List<String> notKeys = [
      'kontrol91',
      'kontrol92',
      'kontrol93',
      'kontrol94',
      'kontrol95',
      'kontrol96',
      'kontrol97',
      'kontrol98',
      'kontrol99',
    ];
    List<String> nonNullNotes = [];

    for (String key in notKeys) {
      var value = record[key];
      if (value != null) {
        nonNullNotes.add(value.toString());
      }
    }

    return nonNullNotes.isNotEmpty ? nonNullNotes.join("\n") : "Not bulunamadı";
  }

  Widget _buildDetailCard(
      {required IconData icon,
      required String title,
      required String content}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 40.0,
              color: Colors.green,
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222F5A),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFF222F5A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void deleteMaintenanceFromDatabase({required String maintenanceID}) async {
  final url =
      Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/maintenance/deleteMaintenance');
  try {
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'maintenanceID': maintenanceID}),
    );

    if (response.statusCode == 200) {
      print('Maintenance record deleted successfully');
    } else {
      print('Failed to delete maintenance record: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}

class BakimPopUp extends StatefulWidget {
  final String maintenanceID;
  final String machineID;

  BakimPopUp({required this.maintenanceID, required this.machineID});

  @override
  _BakimPopUpState createState() => _BakimPopUpState();
}

class _BakimPopUpState extends State<BakimPopUp> {
  TextEditingController maintenanceIdController = TextEditingController();
  TextEditingController maintenanceDateController = TextEditingController();
  List<TextEditingController> noteControllers =
      List.generate(10, (index) => TextEditingController());
  List<String> maintenanceStatuses = List.generate(36, (index) => "1");
  int? selectedState;

  @override
  void initState() {
    super.initState();
  }

  Future<void> editMaintenanceFromDatabase() async {

    String? username = await storage.read(key: 'username');
    String? token = await storage.read(key: 'token');
    // JSON yapısını oluşturun
    Map<String, dynamic> data = {
      'maintenanceID': widget.maintenanceID,
      'machineID': widget.machineID,
      'techinicanID': username,
      'maintenanceStatuses': maintenanceStatuses,
      'notes': noteControllers.map((controller) => controller.text).toList(),
    };

    final Uri uri =
        Uri.parse('https://ondergrup.hidirektor.com.tr/api/v2/authorized/editMaintenance');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // İçerik türü başlığı ekleniyor
        },
        body: json.encode(data), // JSON yapısını body'ye ekleyin
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        print('Maintenance edited successfully!');
        Navigator.of(context).pop(); // Dialog'u kapatın
      } else {
        print('Error editing maintenance: ${response.body}');
      }
    } catch (e) {
      print('Error editing maintenance: $e');
    }
  }

  void showAddMaintenancesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Düzenlemeyi Onayla'
                : 'Confirm Edit',
          ),
          actions: [
            TextButton(
              onPressed: () {
                editMaintenanceFromDatabase();
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'Evet' : 'Yes',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe' ? 'Hayır' : 'No',
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
              ? 'Bakım Kaydı Düzenle'
              : 'Edit Maintenance Log',
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
                ? 'Bakım Kaydını Düzenle'
                : 'Edit Maintenance Log',
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

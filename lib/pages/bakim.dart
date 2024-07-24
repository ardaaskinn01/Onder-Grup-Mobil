import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BakimScreen extends StatefulWidget {
  final String machineID;

  BakimScreen({required this.machineID});

  @override
  _BakimScreenState createState() => _BakimScreenState();
}

class _BakimScreenState extends State<BakimScreen> {
  late Future<List<dynamic>> _maintenanceRecords;

  @override
  void initState() {
    super.initState();
    _maintenanceRecords = getMaintenanceRecords(widget.machineID);
  }

  Future<List<dynamic>> getMaintenanceRecords(String machineID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final url = Uri.parse(
          'http://10.0.2.2:3000/api/maintenance/list?machineID=$machineID');
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
        // Hata mesajını doğrudan ekrana yazdırma
        print('HTTP Hatası: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        throw Exception('Failed to load maintenance records');
      }
    } catch (e) {
      // Hata mesajını doğrudan ekrana yazdırma
      print('Hata oluştu: $e');
      throw Exception('Error occurred while fetching maintenance records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bakım Kayıtları'),
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
            return Center(child: Text('Bakım kaydı bulunamadı'));
          }

          final maintenanceRecords = snapshot.data!;

          return ListView.separated(
            itemCount: maintenanceRecords.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final record = maintenanceRecords[index];
              return ListTile(
                leading: Icon(
                  Icons.build, // Simgeyi duruma göre değiştirebilirsiniz.
                  color: Colors.blue, // Simge rengini ayarlayın.
                  size: 30.0, // Simge boyutunu ayarlayın.
                ),
                title: Text(
                  'ID: ${record['maintenanceID'].toString()}',
                  // ID'yi string olarak dönüştürün.
                  style: TextStyle(
                    fontSize: 18.0, // Yazı boyutunu ayarlayın.
                    fontWeight: FontWeight.bold, // Yazı tipini ayarlayın.
                  ),
                ),
                subtitle: Text(
                  'Bakım Tarihi: ${record['maintenanceDate']}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey, // Alt yazı rengini ayarlayın.
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.0,
                  color: Colors.grey,
                ),
                tileColor: Colors.white,
                // Kartın arka plan rengini ayarlayın.
                onTap: () {
                  // Kart tıklama işlevi
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

  // Kategorilendirme fonksiyonu
  String categorizeControl(int index) {
    if (index >= 0 && index <= 2) {
      return "Fonksiyonlar ve Kontrol";
    } else if (index >= 3 && index <= 7) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Bakım Detayları'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              icon: Icons.perm_identity,
              title: 'Bakım ID',
              content: record['maintenanceID'].toString(),
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.calendar_today,
              title: 'Bakım Tarihi',
              content: record['maintenanceDate'].toString(),
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.check_circle,
              title: 'Kontroller',
              content: _buildControlCategories(record),
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.note,
              title: 'Notlar',
              content:  _buildNotes(record),
            ),
          ],
        ),
      ),
    );
  }

// Kategoriye göre kontrol dizisini oluşturma
  String _buildControlCategories(Map<String, dynamic> record) {
    List<String> categorizedControls = [];
    print(record);
    // İlgili aralıklardaki kontrol anahtarlarını manuel olarak listeleyin
    List<String> kontrolKeys = [
      'kontrol11', 'kontrol12', 'kontrol13', 'kontrol14', // 11-14
      'kontrol21', 'kontrol22', 'kontrol23', 'kontrol24', // 21-24
      'kontrol31', 'kontrol32', 'kontrol33', 'kontrol34', 'kontrol35', 'kontrol36', // 31-36
      'kontrol41', 'kontrol42', 'kontrol43', 'kontrol44', 'kontrol45', 'kontrol46',
      'kontrol51', 'kontrol52', 'kontrol53', 'kontrol54', 'kontrol55', 'kontrol56',
      'kontrol61', 'kontrol62', 'kontrol63',
      'kontrol71', 'kontrol72',
      'kontrol81', 'kontrol82', 'kontrol83',
    ];

    List<String> notKeys = [
      'kontrol91', 'kontrol92', 'kontrol93', 'kontrol94', 'kontrol95', 'kontrol96','kontrol97', 'kontrol98', 'kontrol99',
    ];

    for (int i = 0; i < kontrolKeys.length; i++) {
      String key = kontrolKeys[i];
      if (record[key] == '2') {
        String category = categorizeControl(i);
        categorizedControls.add("$category [Hatalı]");
      }
    }

    return categorizedControls.join("\n"); // Tek bir String'e dönüştürüyoruz
  }

  // Notları filtreleyip birleştirme
  String _buildNotes(Map<String, dynamic> record) {
    List<String> notKeys = [
      'kontrol91', 'kontrol92', 'kontrol93', 'kontrol94', 'kontrol95', 'kontrol96',
      'kontrol97', 'kontrol98', 'kontrol99',
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
      {required IconData icon, required String title, required String content}) {
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
              color: Colors.blueAccent,
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
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87,
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    try {
      final url = Uri.parse(
          'http://10.0.2.2:3000/getMaintenanceRecords?machineID=$machineID');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to load maintenance records');
      }
    } catch (e) {
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
              content: _buildControlCategories(record['kontroller']),
            ),
            SizedBox(height: 16.0),
            _buildDetailCard(
              icon: Icons.note,
              title: 'Notlar',
              content: record['notes'].toString(),
            ),
          ],
        ),
      ),
    );
  }

  // Kategoriye göre kontrol dizisini oluşturma
  String _buildControlCategories(List<dynamic> kontrolList) {
    List<String> categorizedControls = [];

    for (int i = 0; i < kontrolList.length; i++) {
      if (kontrolList[i] == '2') {
        String category = categorizeControl(i);
        categorizedControls.add("$category [Hatalı]");
      }
    }

    return categorizedControls.join("\n"); // Tek bir String'e dönüştürüyoruz
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
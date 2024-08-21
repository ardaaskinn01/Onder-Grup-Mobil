import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'languageprovider.dart';

class HataScreen extends StatefulWidget {
  final String machineID;

  HataScreen({required this.machineID});

  @override
  _HataScreenState createState() => _HataScreenState();
}

class _HataScreenState extends State<HataScreen> {
  late Future<List<dynamic>> _errorRecords;

  @override
  void initState() {
    super.initState();
    _errorRecords = getMaintenanceRecords(widget.machineID);
  }

  Future<List<dynamic>> getMaintenanceRecords(String machineID) async {
    try {
      final url = Uri.parse('http://85.95.231.92:3001/getMaintenanceRecords?machineID=$machineID');
      final response = await http.get(url);

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
        title: Text(languageProvider.getLocalizedString('hata_kayitlari')),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _errorRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${languageProvider.getLocalizedString('hata_olustu')}: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(languageProvider.getLocalizedString('hata_kaydi_bulunamadi')),
            );
          }

          final errorRecords = snapshot.data!;

          return ListView.separated(
            itemCount: errorRecords.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final record = errorRecords[index];
              return ListTile(
                title: Text(record['errorId'] ?? languageProvider.getLocalizedString('no_id_data')),
              );
            },
          );
        },
      ),
    );
  }
}
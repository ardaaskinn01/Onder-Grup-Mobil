import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final url = Uri.parse('http://10.0.2.2:3000/getMaintenanceRecords?machineID=$machineID');
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
        future: _errorRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Hata kaydı bulunamadı'));
          }

          final errorRecords = snapshot.data!;

          return ListView.separated(
            itemCount: errorRecords.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final record = errorRecords[index];
              return ListTile(
                title: Text(record['errorId'] ?? 'no id data'),
              );
            },
          );
        },
      ),
    );
  }
}
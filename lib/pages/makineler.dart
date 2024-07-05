import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../bakimvariables.dart';
import 'bakim.dart';
import 'hata.dart';

class MakinelerScreen extends StatefulWidget {
  @override
  @override
  _MakinelerScreenState createState() => _MakinelerScreenState();
}

class _MakinelerScreenState extends State<MakinelerScreen> {

  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>> _getMachines() async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/getMachines'); // Express.js server adresine göre güncelleyin
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load machines');
      }
    } catch (e) {
      print('Error fetching machines: $e');
      throw Exception('Error occurred while fetching machines: $e');
    }
  }

  Future<void> deleteMachine(String machineName) async {
    try {
      final url = Uri.parse('http://10.0.2.2:3000/deleteMachine?machineName=$machineName'); // Yeni backend URL'sini kullanın
      final response = await http.delete(
        url,
        headers: <String, String>{
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (!snapshot.hasData) {
                          return Text('Veri bulunamadı');
                        }
                        var machines = snapshot.data as List;
                        return Padding(
                          padding: EdgeInsets.only(
                              top: 20.0), // Dikeyde 20 birimlik boşluk ekler
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 35,
                                columns: [
                                  DataColumn(label: Text('   ID')),
                                  DataColumn(label: Text('İsim')),
                                  DataColumn(label: Text('Tür')),
                                  DataColumn(label: Text(' İncele')),
                                  DataColumn(label: Text('    Sil')),
                                ],
                                rows: machines.map((machine) {
                                  return DataRow(cells: [
                                    DataCell(
                                      Text(
                                        machine['machineID'],
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
                                        icon: Icon(Icons.visibility,
                                            color: Color(0xFF222F5A)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MachineScreen(
                                                      machineID: machine[
                                                          'machineID']),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Color(0xFFBE1522)),
                                        onPressed: () async {
                                          var machineIdToDelete =
                                              machine['machineName'];
                                          await deleteMachine(
                                              machineIdToDelete);
                                          setState(() {}); // UI'yı güncelle
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
  final String machineID;

  MachineScreen({required this.machineID});
}

class _MachineScreenState extends State<MachineScreen> {
  late User receivedUser;

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
    try {
      final url = Uri.parse(
          'http://10.0.2.2:3000/getMachineDetails?machineID=${widget.machineID}'); // Yeni backend URL'sini kullanın
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          machineName = data['machineName'];
          machineID = data['machineID'];
          machineType = data['machineType'];
          machineDetails = data;
        });
      } else {
        throw Exception(
            'Makine detayları alınamadı, Hata Kodu: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Makine detayları alınırken hata oluştu: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Machine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: machineDetails.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    machineName,
                    style: TextStyle(
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
                  SizedBox(height: 10.0),
                  SizedBox(
                    height: 60.0, // İstenilen yüksekliği ayarlayın
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HataScreen(
                                      machineID: widget.machineID),
                                ),
                              );
                            },
                            child: Container(
                              color: Color(0xFFBE1522),
                              padding: EdgeInsets.all(0.0),
                              child: Center(
                                // Metni ortalamak için Center widget'ını kullanın
                                child: ListTile(
                                  title: Text(
                                    'Machine Error Log',
                                    style: TextStyle(
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
                        SizedBox(
                            width:
                                18.0), // İstenilen boşluk genişliğini ayarlayın
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BakimScreen(
                                      machineID: widget.machineID),
                                ),
                              );
                            },
                            child: Container(
                              color: Color(0xFF222F5A),
                              padding: EdgeInsets.all(0.0),
                              child: Center(
                                child: ListTile(
                                  title: Text(
                                    'Machine Maintenance Log',
                                    style: TextStyle(
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
                  SizedBox(height: 20.0),
                  Expanded(
                    child: ListView(
                      children: machineDetails.entries.map((entry) {
                        return ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value.toString()),
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

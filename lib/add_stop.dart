// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/search_example.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key});

  @override
  _AddStopScreenState createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  final TextEditingController _stopController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  String selectedpoint = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Stop',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              controller: _stopController,
              decoration: InputDecoration(
                labelText: 'Stop Name',
                border: const OutlineInputBorder(),
                hintText: 'wanna select from map? Click here 👉🏻',
                suffixIcon: GestureDetector(
                  onTap: () async {
                    final selectedPoint = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationAppExample(),
                      ),
                    );
                    if (selectedPoint != null) {
                      osm.GeoPoint geoPoint = selectedPoint;
                      double latitude = geoPoint.latitude;
                      double longitude = geoPoint.longitude;
                      final response = await http.get(
                        Uri.parse(
                          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
                        ),
                      );

                      if (response.statusCode == 200) {
                        Map<String, dynamic> data = json.decode(response.body);
                        print(data['name']);
                        _stopController.text = data['name'];
                        setState(() {
                          selectedpoint = selectedPoint.toString();
                        });
                      } else {
                        throw Exception('Failed to load place name');
                      }
                    }
                  },
                  child: const Icon(Icons.location_searching_rounded),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'tags',
                hintText: 'Seperate each tag using (,)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String stop = _stopController.text.trim();
                String tag = _tagController.text.trim();
                RegExp commaSeparatedTags =
                    RegExp(r'^[a-zA-Z]+(?:,[a-zA-Z]+)*$');

                if (stop.isNotEmpty &&
                    tag.isNotEmpty &&
                    commaSeparatedTags.hasMatch(tag)) {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                        'useraddedstops': FieldValue.arrayUnion([
                          {
                            'stop': stop,
                            'tags': tag,
                            'selectedPoint': selectedpoint,
                          }
                        ])
                      });
                    }
                  } catch (e) {
                    String errorMessage = e.toString();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error!'),
                          content: Text(errorMessage),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                  Navigator.pop(context);
                } else {
                  String errorMessage = 'Invalid input.';

                  if (tag.isEmpty) {
                    errorMessage = 'Tags are required.';
                  } else if (!commaSeparatedTags.hasMatch(tag)) {
                    errorMessage = 'Tags must be separated by commas.';
                  }

                  // Show a dialog or a message to inform the user of the error.
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Invalid Input'),
                        content: Text(errorMessage),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text('Add Stop'),
            ),
          ],
        ),
      ),
    );
  }
}

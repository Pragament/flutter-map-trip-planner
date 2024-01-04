// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/screens/all_routes.dart';
import 'package:driver_app/miscellaenous/search_example.dart';
import 'package:driver_app/widgets/tags_auto_completion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:location/location.dart';
import 'package:textfield_tags/textfield_tags.dart';

class AddStopScreen extends StatefulWidget {
  AddStopScreen({
    super.key,
    required this.filteredTag,
    required this.allTags,
    required this.currentLocation,
    required this.locationName,
  });

  final String? filteredTag;
  late List<String>? allTags;
  final LocationData? currentLocation;
  final String? locationName;

  @override
  _AddStopScreenState createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  late TextEditingController _stopController;
  late TextfieldTagsController _textfieldTagsController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<String> displayTags = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _stopController = TextEditingController(text: widget.locationName);
    _textfieldTagsController = TextfieldTagsController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    if (widget.filteredTag != null) {
      displayTags.add(widget.filteredTag!);
    }
    print(widget.currentLocation);
    print(widget.locationName);
  }

  String selectedpoint = "";

  @override
  Widget build(BuildContext context) {
    print('Data = ${widget.allTags}');
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
                    osm.GeoPoint selectedLocation = osm.GeoPoint(
                      latitude: widget.currentLocation!.latitude!,
                      longitude: widget.currentLocation!.longitude!,
                    );
                    final selectedPoint = await showSimplePickerLocation(
                      context: context,
                      isDismissible: true,
                      title: "Select Stop",
                      textConfirmPicker: "pick",
                      zoomOption: const ZoomOption(
                        initZoom: 15,
                      ),
                      initPosition: selectedLocation,
                      radius: 15.0,
                    );
                    if (selectedPoint != null) {
                      osm.GeoPoint geoPoint = selectedPoint;
                      double latitude = geoPoint.latitude;
                      double longitude = geoPoint.longitude;
                      _stopController.text =
                          (await getPlaceName(latitude, longitude))!;
                    }
                  },
                  child: const Icon(Icons.location_searching_rounded),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TagsAutoCompletion(textfieldTagsController: _textfieldTagsController, allTags: widget.allTags, displayTags: displayTags),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Custom Title',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Custom Description',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String stop = _stopController.text.trim();
                String tag = '';
                List<String> tagsList = _textfieldTagsController.getTags!;
                if (tagsList.isNotEmpty) {
                  for (int i = 0; i < tagsList.length; i++) {
                    if (i == tagsList.length - 1) {
                      tag += tagsList[i];
                      break;
                    }
                    tag += '${tagsList[i]},';
                  }
                }
                print(tag);
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
                        ]),
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

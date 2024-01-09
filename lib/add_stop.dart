// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/all_routes.dart';
import 'package:driver_app/search_example.dart';
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
            Autocomplete<String>(
              optionsViewBuilder: (context, onSelected, options) {
                return Container(
                  margin: const EdgeInsets.only(right: 30),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final dynamic option = options.elementAt(index);
                            return TextButton(
                              onPressed: () {
                                onSelected(option);
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '#$option',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 74, 137, 92),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return widget.allTags!.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selectedTag) {
                _textfieldTagsController.addTag = selectedTag;
              },
              fieldViewBuilder: (context, ttec, tfn, onFieldSubmitted) {
                return TextFieldTags(
                  textEditingController: ttec,
                  focusNode: tfn,
                  textfieldTagsController: _textfieldTagsController,
                  initialTags: displayTags,
                  textSeparators: const [' ',','],
                  letterCase: LetterCase.normal,
                  validator: (String tag) {
                    if (_textfieldTagsController.getTags!.contains(tag)) {
                      return 'you already entered that';
                    }
                    return null;
                  },
                  inputfieldBuilder:
                      (context, tec, fn, error, onChanged, onSubmitted) {
                    return ((context, sc, tags, onTagDelete) {
                      return TextField(
                        controller: tec,
                        focusNode: fn,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          helperStyle: const TextStyle(
                            color: Color.fromARGB(255, 74, 137, 92),
                          ),
                          labelText: 'tags',
                          hintText: 'Seperate each tag using (,)',
                          errorText: error,
                          prefixIcon: tags.isNotEmpty
                              ? SingleChildScrollView(
                                  controller: sc,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: tags.map((String tag) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20.0),
                                        ),
                                        color: Color.fromARGB(255, 74, 137, 92),
                                      ),
                                      margin:
                                          const EdgeInsets.only(right: 10.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            child: Text(
                                              '#$tag',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            onTap: () {
                                              //print("$tag selected");
                                            },
                                          ),
                                          const SizedBox(width: 4.0),
                                          InkWell(
                                            child: const Icon(
                                              Icons.cancel,
                                              size: 14.0,
                                              color: Color.fromARGB(
                                                  255, 233, 233, 233),
                                            ),
                                            onTap: () {
                                              onTagDelete(tag);
                                            },
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                )
                              : null,
                        ),
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                      );
                    });
                  },
                );
              },
            ),
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

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/providers/loading_provider.dart';
import 'package:driver_app/providers/route_provider.dart';
import 'package:driver_app/widgets/tags_auto_completion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../utilities/location_functions.dart';

class AddStopScreen extends StatefulWidget {
  AddStopScreen({
    super.key,
    required this.filteredTags,
    required this.allTags,
    required this.currentLocationData,
    required this.locationName,
  });

  final List<String> filteredTags;
  late List<String>? allTags;
  LocationData? currentLocationData;
  final String? locationName;

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  late TextEditingController _stopController;
  late TextfieldTagsController _textfieldTagsController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<String> displayTags = [];
  late flutterMap.MapController flutterMapController;
  LatLng? locationPoint;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    flutterMapController = flutterMap.MapController();
    _stopController = TextEditingController(text: widget.locationName);
    _textfieldTagsController = TextfieldTagsController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    displayTags = [...widget.filteredTags];
    displayTags.remove('All');
      locationPoint = LatLng(widget.currentLocationData!.latitude!,
        widget.currentLocationData!.longitude!);
    marker = marker = flutterMap.Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(widget.currentLocationData!.latitude!, widget.currentLocationData!.longitude!),
      child:  const Icon(
        Icons.circle_sharp,
        color: Colors.blue,
        size: 16,
      ),
    );
  }

  void _saveToFirebase(final newStop) async
  {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'useraddedstops': FieldValue.arrayUnion([
          newStop
        ]),
      });
    }
  }

  String _selectedPoint = "";

  late flutterMap.Marker marker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Stop',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber,
        actions: [
          ElevatedButton(
            onPressed: () {
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
              RegExp commaSeparatedTags = RegExp(r'^[a-zA-Z]+(?:,[a-zA-Z]+)*$');
              print(_stopController.text);
              print(_textfieldTagsController.getTags);
              print(tag);
              print(_selectedPoint);
              print(commaSeparatedTags.hasMatch(tag));

              if (_stopController.text.isNotEmpty &&
                  tag.isNotEmpty &&
                  commaSeparatedTags.hasMatch(tag)) {
                try {
                  final newStop = {
                    'stop': stop,
                    'tags': tag,
                    'selectedPoint': _selectedPoint,
                  };
                  double latitude = double.parse(
                      _selectedPoint.split(',')[0].split(':')[1].trim());
                  double longitude = double.parse(_selectedPoint
                      .split(',')[1]
                      .split(':')[1]
                      .replaceAll('}', '')
                      .trim());
                  Provider.of<RouteProvider>(context, listen:  false).addStop(
                      {
                        'stop': stop,
                        'tags': tag,
                        'selectedPoint': LatLng(latitude, longitude),
                      },
                  );
                  _saveToFirebase(newStop);
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
                Navigator.pop(context, true);
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
          const SizedBox(
            width: 15,
          ),
        ],
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
                    osm.GeoPoint selectedLocation = locationPoint != null ? osm.GeoPoint(
                      latitude: locationPoint!.latitude,
                      longitude: locationPoint!.longitude,
                    ) : osm.GeoPoint(
                      latitude: widget.currentLocationData!.latitude!,
                      longitude: widget.currentLocationData!.longitude!,
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
                      _selectedPoint = geoPoint.toString();
                      setState(() {
                        locationPoint = LatLng(latitude, longitude);
                      });
                      _stopController.text =
                          (await getPlaceName(latitude, longitude))!;
                      flutterMapController.move(
                          LatLng(latitude, longitude), 14);
                    }
                  },
                  child: const Icon(Icons.location_searching_rounded),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TagsAutoCompletion(
              textfieldTagsController: _textfieldTagsController,
              allTags: widget.allTags,
              displayTags: displayTags,
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
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    child: flutterMap.FlutterMap(
                      mapController: flutterMapController,
                      options: flutterMap.MapOptions(
                        initialCenter: locationPoint!,
                        initialZoom: 14.0,
                      ),
                      children: [
                        flutterMap.TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        ),
                        flutterMap.MarkerLayer(
                          markers: [
                            flutterMap.Marker(
                              width: 80.0,
                              height: 80.0,
                              point: locationPoint!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.black,
                              ),
                            ),
                            marker,
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Consumer<LoadingProvider>(
                      builder: (BuildContext context,
                          LoadingProvider loadingProvider, Widget? child) {
                        return FloatingActionButton(
                          onPressed: () async {
                            loadingProvider
                                .changeAddStopsUpdateLocationState(true);
                            widget.currentLocationData = await fetchCurrentLocation();
                            loadingProvider
                                .changeAddStopsUpdateLocationState(false);
                            print('Updated Location  ==>  ${widget.currentLocationData}');
                            flutterMapController.move(
                                LatLng(
                                  widget.currentLocationData!.latitude!,
                                  widget.currentLocationData!.longitude!,
                                ),
                                14);
                            setState(() {
                              marker = marker = flutterMap.Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(widget.currentLocationData!.latitude!, widget.currentLocationData!.longitude!),
                                child:  const Icon(
                                  Icons.circle_sharp,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              );
                            });
                            // _stopController.text = (await getPlaceName(widget.currentLocationData!.latitude!, widget.currentLocationData!.longitude!))!;
                          },
                          child: loadingProvider.addStopUpdateLocation
                              ? const Center(
                                  child: SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.location_searching,
                                ),
                        );
                      },
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

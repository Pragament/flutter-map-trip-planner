import 'package:flutter/material.dart';

import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:location/location.dart';

import 'package:flutter_map_trip_planner/models/place_geo_points.dart';
import '../data/find_place.dart';
import '../models/place_suggestion.dart';

class RouteAddStopScreen extends StatefulWidget {
  const RouteAddStopScreen({
    required this.currentLocationData,
    required this.displayedUserAddedStops,
    super.key,
  });

  final LocationData currentLocationData;
  final List<Map<String, dynamic>> displayedUserAddedStops;

  @override
  State<RouteAddStopScreen> createState() => _RouteAddStopScreenState();
}

class _RouteAddStopScreenState extends State<RouteAddStopScreen> {
  TextEditingController searchFieldController = TextEditingController();
  TextEditingController googleSearchController = TextEditingController();
  late FindPlace findPlace;
  late List<Map<String, dynamic>> filteredList;
  late Future<List<Suggestion>> suggestions;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    findPlace = FindPlace();
    filteredList = widget.displayedUserAddedStops;
    suggestions =
        FindPlace().placeNameAutocompletion('', widget.currentLocationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Choose Destination'),
        backgroundColor: Colors.amberAccent,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
        child: SingleChildScrollView(
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  osm.GeoPoint currentLocation = osm.GeoPoint(
                    latitude: widget.currentLocationData.latitude!,
                    longitude: widget.currentLocationData.longitude!,
                  );
                  Navigator.pop(context, [null, currentLocation]);
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.my_location_sharp,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Your location',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              InkWell(
                onTap: () async {
                  osm.GeoPoint selectedLocation = osm.GeoPoint(
                    latitude: widget.currentLocationData.latitude!,
                    longitude: widget.currentLocationData.longitude!,
                  );
                  osm.GeoPoint geoPoint;
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
                    geoPoint = selectedPoint;
                  } else {
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context, [null, geoPoint]);
                  }
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_sharp,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text('Choose on map', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const Divider(
                height: 20,
                thickness: 2,
              ),
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                height: 250,
                child: Column(
                  children: [
                    TextField(
                      controller: googleSearchController,
                      onChanged: (place) {
                        setState(() {
                          suggestions = FindPlace().placeNameAutocompletion(
                              place ?? '', widget.currentLocationData);
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter Stop Name',
                        // suffixIcon: InkWell(
                        //   onTap: () async {
                        //     Place place =
                        //     await findPlace.findPlaceByName(
                        //         googleSearchController.text);
                        //     if (context.mounted) {
                        //       Navigator.pop(context, [
                        //         place.placeName,
                        //         place.selectedPoint
                        //       ]);
                        //     }
                        //   },
                        //   child: Container(
                        //     decoration: BoxDecoration(
                        //         borderRadius:
                        //         BorderRadius.circular(10),
                        //         color: Colors.blue),
                        //     child: const Icon(
                        //       Icons.search_sharp,
                        //       color:
                        //       CupertinoColors.lightBackgroundGray,
                        //     ),
                        //   ),
                        // ),
                      ),
                    ),
                    FutureBuilder(
                        future: suggestions,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.data != null) {
                            print(snapshot.data?[0].placeName);
                            return SizedBox(
                              height: 200,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data?.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    onTap: () async {
                                      PlaceGeoPoints geoPoints =
                                          await FindPlace().fetchPlaceGeoPoints(
                                              snapshot.data![index].placeId);
                                      if (context.mounted) {
                                        Navigator.pop(context, [
                                          snapshot.data![index].placeName,
                                          geoPoints.selectedPoint
                                        ]);
                                      }
                                    },
                                    title:
                                        Text(snapshot.data![index].placeName),
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                  ],
                ),
              ),
              const Divider(
                height: 20,
                thickness: 2,
              ),
              Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'UserAddedStops',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchFieldController,
                    decoration: InputDecoration(
                      hintText: 'Search by Stop Name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_sharp),
                        onPressed: () {
                          String value =
                              searchFieldController.text.replaceAll(' ', '');
                          if (value.isEmpty) {
                            setState(() {
                              filteredList = widget.displayedUserAddedStops;
                            });
                            return;
                          }
                          List<Map<String, dynamic>> result = widget
                              .displayedUserAddedStops
                              .where((stop) => stop['stop']
                                  .toString()
                                  .replaceAll(' ', '')
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                          setState(() {
                            filteredList = result;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        setState(() {
                          filteredList = widget.displayedUserAddedStops;
                        });
                        return;
                      }
                      List<Map<String, dynamic>> result = widget
                          .displayedUserAddedStops
                          .where((stop) => stop['stop']
                              .toString()
                              .replaceAll(' ', '')
                              .toLowerCase()
                              .contains(
                                  value..replaceAll(' ', '').toLowerCase()))
                          .toList();
                      setState(() {
                        filteredList = result;
                      });
                    },
                  ),
                  // SizedBox(
                  //   height: 40,
                  //   width: double.infinity,
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     children: [
                  //       TextButton(
                  //         onPressed: () {
                  //           AlertDialog alertDialog = AlertDialog(
                  //             title:
                  //           );
                  //           showDialog(
                  //             context: context,
                  //             builder: (BuildContext context) {
                  //               return alertDialog;
                  //             },
                  //           );
                  //         },
                  //         child: const Text(
                  //           'can\'t find what you are looking?',
                  //           style: TextStyle(
                  //             color: Color(0xFF0070E0),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  filteredList.isEmpty
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          child: Column(
                            children: filteredList.map((stop) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        readOnly: true,
                                        controller: TextEditingController(
                                            text: stop['stop']),
                                        decoration: const InputDecoration(
                                          labelText: 'Stop',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      onPressed: () {
                                        var selectedPoint =
                                            stop['selectedPoint'];
                                        Navigator.pop(
                                          context,
                                          [
                                            stop['stop'],
                                            osm.GeoPoint(
                                              latitude: selectedPoint.latitude,
                                              longitude:
                                                  selectedPoint.longitude,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

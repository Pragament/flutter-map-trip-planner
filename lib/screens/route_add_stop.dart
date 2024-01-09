import 'package:flutter/material.dart';

import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:location/location.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Destination'),
        backgroundColor: Colors.amberAccent,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                osm.GeoPoint currentLocation = osm.GeoPoint(
                  latitude: widget.currentLocationData.latitude!,
                  longitude: widget.currentLocationData.longitude!,
                );
                Navigator.pop(context, currentLocation);
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
                  Navigator.pop(context, geoPoint);
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
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'UserAddedStops',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  widget.displayedUserAddedStops.isEmpty
                      ? const SizedBox.shrink()
                      : Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                              children: widget.displayedUserAddedStops.map((stop) {
                                print('Stop : $stop');
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
                                          var selectedPoint = stop['selectedPoint'];
                                          print(selectedPoint);
                                          RegExp regex =
                                              RegExp(r'([0-9]+\.[0-9]+)');
                                          Iterable<Match> matches =
                                              regex.allMatches(selectedPoint);
                                          double latitude = double.parse(
                                              matches.elementAt(0).group(0)!);
                                          double longitude = double.parse(
                                              matches.elementAt(1).group(0)!);
                                          Navigator.pop(
                                            context,
                                            osm.GeoPoint(
                                              latitude: latitude,
                                              longitude: longitude,
                                            ),
                                          );
                                          // _stopnameController.text = stop['stop'];
                                          // _stopControllers.add(
                                          //   TextEditingController(
                                          //     text: selectedPoint,
                                          //   ),
                                          // );
                                          // // Remove the added stop from displayedUserAddedStops
                                          // widget.displayedUserAddedStops.remove(stop);
                                          // setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
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

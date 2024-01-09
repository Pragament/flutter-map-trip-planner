// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:rrule_generator/rrule_generator.dart';
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import '../all_routes.dart';
import '../search_example.dart';
import '../rrule_date_calculator.dart';

class RouteCreationScreen extends StatefulWidget {
  const RouteCreationScreen({required this.currentLocationData, required this.locationName, super.key});

  final LocationData? currentLocationData;
  final String? locationName;

  @override
  _RouteCreationScreenState createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  final List<TextEditingController> _stopNameControllers = [];
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _stopnameController = TextEditingController();
  List<Map<String, dynamic>> displayedUserAddedStops = [];
  List<Map<String, dynamic>> copy = [];
  final List<FocusNode> _stopFocusNodes = [FocusNode()];
  late flutterMap.MapController flutterMapController;
  List<LatLng> stops = [];

  // List<TextEditingController> _selectedStopControllers = [];

  void _addStop() async {
    osm.GeoPoint selectedLocation = osm.GeoPoint(
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
      String? updatedStopName = await getPlaceName(
          selectedPoint.latitude, selectedPoint.longitude);
      String updatedStop = selectedPoint.toString();
      setState(() {
        _stopNameControllers.add(TextEditingController(text: updatedStopName));
        _stopControllers.add(TextEditingController(text: updatedStop));
        _stopFocusNodes.add(FocusNode());
        stops.add(LatLng(selectedPoint.latitude, selectedPoint.longitude));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    osm.GeoPoint geoPoint = osm.GeoPoint(latitude: widget.currentLocationData!.latitude!, longitude: widget.currentLocationData!.longitude!);
    _stopNameControllers.add(TextEditingController(text: widget.locationName));
    _stopControllers.add(TextEditingController(text: geoPoint.toString()));
    flutterMapController = flutterMap.MapController();
    stops.add(LatLng(widget.currentLocationData!.latitude!, widget.currentLocationData!.longitude!));
    _fetchUserAddedStops();
  }

  @override
  void dispose() {
    for (var node in _stopFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _removeStop(int index) {
    setState(() {
      if (index >= 0 && index < _stopControllers.length) {
        var removedStop = _stopControllers[index].text;
        var stopname = _stopnameController.text;
        print(copy);
        bool isStopInCopy = copy.any((e) => e['selectedPoint'] == removedStop);
        if (isStopInCopy) {
          displayedUserAddedStops
              .add({'stop': stopname, 'selectedPoint': removedStop});
        }
        _stopNameControllers.removeAt(index);
        _stopControllers.removeAt(index);
        _stopFocusNodes.removeAt(index);
        stops.removeAt(index);
      }
    });
  }

  Future<void> _fetchUserAddedStops() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      List<dynamic> userAddedStopsData = userDoc.get('useraddedstops') ?? [];
      displayedUserAddedStops = userAddedStopsData.map((stopData) {
        return {
          'stop': stopData['stop'],
          'selectedPoint': stopData['selectedPoint']
        };
      }).toList();
      copy = userAddedStopsData.map((stopData) {
        return {
          'stop': stopData['stop'],
          'selectedPoint': stopData['selectedPoint']
        };
      }).toList();
    }
    setState(() {
      displayedUserAddedStops = displayedUserAddedStops;
    });
  }

  void _saveRoute() async {
    String routeName = _routeNameController.text;
    List<String> stops =
        _stopControllers.map((controller) => controller.text).toList();
    String? generatedRRule = generatedRRuleNotifier.value;
    String? tags = _tagsController.text;
    if (tags.isEmpty) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Missing Tags'),
              content: const Text('Please enter at least one tag.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          });
    }
    RegExp tagRegExp = RegExp(r'^[a-zA-Z]+(?:,[a-zA-Z]+)*$');
    if (!tagRegExp.hasMatch(tags)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Tags'),
            content:
                const Text('Tags must consist of letters separated by commas.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
      return; // Exit function if tags are invalid
    }

    if (routeName.isNotEmpty && stops.length >= 2) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          String userID = user.uid;
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(userID);

          List<DateTime> dates = [];

          if (generatedRRule != null && generatedRRule.isNotEmpty) {
            RecurringDateCalculator dateCalculator =
                RecurringDateCalculator(generatedRRule);
            dates = dateCalculator.calculateRecurringDates();
          }

          await userRef.update({
            'routes': FieldValue.arrayUnion([
              {
                'routeID': DateTime.now().millisecondsSinceEpoch.toString(),
                'routeName': routeName,
                'stops': stops,
                'rrule': generatedRRule,
                'dates': dates.map((date) => date.toIso8601String()).toList(),
                'tags': tags,
              }
            ]),
          });

          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Route added!'),
                  content: const Text('Routes saved successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/allroutes', (route) => false);
                      },
                      child: const Text('Ok'),
                    ),
                  ],
                );
              });
        } else {
          print('User is not authenticated.');
        }
      } catch (e) {
        print('Error saving route: $e');

        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Error!'),
                content: Text('Error Saving routes: $e'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Ok'),
                  ),
                ],
              );
            });
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Route'),
            content: const Text(
                'Please provide a non-empty route name and at least two stops.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }

  final ValueNotifier<String?> generatedRRuleNotifier = ValueNotifier(null);
  String? savedRRule;
  void _scheduleRoute() async {
    final rrule = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: SingleChildScrollView(
          child: RRuleGenerator(
            initialRRule: savedRRule ?? '',
            config: RRuleGeneratorConfig(),
            textDelegate: const EnglishRRuleTextDelegate(),
            onChange: (rrule) {
              generatedRRuleNotifier.value = rrule;
            },
          ),
        ),
        actions: <Widget>[
          const Text(
            'Don\'t skip stop conditions or else you will end up with error!',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final rrule = generatedRRuleNotifier.value;
              // print(rrule);
              Navigator.of(context).pop(rrule);
            },
          ),
        ],
      ),
    );
    if (rrule != null) {
      generatedRRuleNotifier.value = rrule;
      setState(() {
        savedRRule = rrule;
      });
    }
  }

  osm.GeoPoint parseGeoPoint(String geoPointString)
  {
    RegExp regex = RegExp(r'([0-9]+\.[0-9]+)');
    Iterable<Match> matches = regex.allMatches(geoPointString);

    double latitude = double.parse(matches.elementAt(0).group(0)!);
    double longitude = double.parse(matches.elementAt(1).group(0)!);
    return osm.GeoPoint(
      latitude: latitude, longitude: longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Route',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber,
        actions: [
          ElevatedButton(
            onPressed: _saveRoute,
            child: const Text('Save Route'),
          ),
          const SizedBox(
            width: 15,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 60,
              width: double.infinity,
              child: TextField(
                controller: _routeNameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 60,
                    width : MediaQuery.of(context).size.width * 0.55,
                    child: TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.33,
                    child: ElevatedButton(
                      onPressed: _scheduleRoute,
                      child: const Text('Schedule Route'),
                    ),
                  ),
                ],
              ),
            ),
            // Column(
            //   children: [
            //     const SizedBox(height: 16),
            //     const Text(
            //       'UserAddedStops',
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     const SizedBox(height: 16),
            //     displayedUserAddedStops.isEmpty
            //         ? const SizedBox.shrink()
            //         : Column(
            //             children: displayedUserAddedStops.map((stop) {
            //               return Padding(
            //                 padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            //                 child: Row(
            //                   children: [
            //                     Expanded(
            //                       child: TextField(
            //                         readOnly: true,
            //                         controller: TextEditingController(
            //                             text: stop['stop']),
            //                         decoration: const InputDecoration(
            //                           labelText: 'Stop',
            //                           border: OutlineInputBorder(),
            //                         ),
            //                       ),
            //                     ),
            //                     IconButton(
            //                       icon: const Icon(Icons.add_circle),
            //                       onPressed: () {
            //                         var selectedPoint = stop['selectedPoint'];
            //                         _stopnameController.text = stop['stop'];
            //                         _stopControllers.add(
            //                           TextEditingController(
            //                               text: selectedPoint,
            //                           ),
            //                         );
            //                         // Remove the added stop from displayedUserAddedStops
            //                         displayedUserAddedStops.remove(stop);
            //                         // setState(() {});
            //                       },
            //                     ),
            //                   ],
            //                 ),
            //               );
            //             }).toList(),
            //           ),
            //   ],
            // ),
            const SizedBox(height: 16),
            const Text(
              'Stops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // TextField(
            //   decoration: InputDecoration(
            //     labelText: 'stop',
            //     hintText: 'Select Sop',
            //     border: const OutlineInputBorder(),
            //     suffixIcon: IconButton(
            //       onPressed: () async {
            //         osm.GeoPoint selectedLocation = osm.GeoPoint(
            //           latitude: widget.currentLocationData!.latitude!,
            //           longitude: widget.currentLocationData!.longitude!,
            //         );
            //         final selectedPoint = await showSimplePickerLocation(
            //           context: context,
            //           isDismissible: true,
            //           title: "Select Stop",
            //           textConfirmPicker: "pick",
            //           zoomOption: const ZoomOption(
            //             initZoom: 15,
            //           ),
            //           initPosition: selectedLocation,
            //
            //           radius: 15.0,
            //         );
            //         if (selectedPoint != null) {
            //           osm.GeoPoint geoPoint = selectedPoint;
            //           double latitude = geoPoint.latitude;
            //           double longitude = geoPoint.longitude;
            //           _stopController.text =
            //           (await getPlaceName(latitude, longitude))!;
            //         }
            //         if (selectedPoint != null) {
            //         osm.GeoPoint geoPoint = selectedPoint;
            //         double latitude = geoPoint.latitude;
            //         double longitude = geoPoint.longitude;
            //         final response = await http.get(
            //         Uri.parse(
            //         'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
            //         ),
            //         );
            //
            //         if (response.statusCode == 200) {
            //         Map<String, dynamic> data = json.decode(response.body);
            //         print(data['name']);
            //         _stopController.text = data['name'];
            //         setState(() {
            //         selectedpoint = selectedPoint.toString();
            //         });
            //         } else {
            //         throw Exception('Failed to load place name');
            //         }
            //         }
            //       },
            //       icon: const Icon(Icons.gps_not_fixed),
            //     )
            //   ),
            // ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _stopNameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          height : 60,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: TextField(
                            readOnly: true,
                            controller: _stopNameControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Stop ${index + 1}',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  final selectedPoint = await showSimplePickerLocation(
                                    context: context,
                                    isDismissible: true,
                                    title: "Select Stop",
                                    textConfirmPicker: "pick",
                                    zoomOption: const ZoomOption(
                                      initZoom: 15,
                                    ),
                                    initPosition: parseGeoPoint(_stopControllers[index].text),
                                    radius: 15.0,
                                  );
                                  if (selectedPoint != null) {
                                    osm.GeoPoint geoPoint = selectedPoint;
                                    double latitude = geoPoint.latitude;
                                    double longitude = geoPoint.longitude;
                                    setState(() {
                                      stops[index] = LatLng(latitude, longitude);
                                    });
                                    _stopNameControllers[index].text =
                                    (await getPlaceName(latitude, longitude))!;
                                    _stopControllers[index].text = geoPoint.toString();
                                }
                                },
                                icon: const Icon(Icons.gps_not_fixed),
                              )
                            ),
                          ),
                        ),
                        if(index >= 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => _removeStop(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addStop,
              child: const Text('Add Stop'),
            ),
            Expanded(
              child: flutterMap.FlutterMap(
                mapController: flutterMapController,
                options: flutterMap.MapOptions(
                  initialCenter:  LatLng(
                    widget.currentLocationData!.latitude!,
                    widget.currentLocationData!.longitude!,
                  ),
                  initialZoom: 14.0,
                ),
                children: [
                  flutterMap.TileLayer(
                    urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                    flutterMap.PolylineLayer(
                      polylines: [
                        flutterMap.Polyline(
                          points: stops,
                          strokeWidth: 4,
                          color:  Colors.blue,
                          ),
                      ],
                    ),
                    flutterMap.MarkerLayer(
                      markers: [
                        for(int i = 0; i < stops.length; i++)
                          flutterMap.Marker(
                            width: 80.0,
                            height: 80.0,
                            point: stops[i],
                            child: Stack(
                              children: [
                                const Positioned(
                                  top: 17.4,
                                  left: 28,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.black,
                                  ),
                                ),
                                Positioned(
                                  top: 27.4,
                                  left: 25,
                                  child: Text(
                                    '${i+1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: generatedRRuleNotifier,
              builder: (context, savedRRule, child) {
                return savedRRule != null
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: Colors.black,
                            )),
                        child: Text(
                          'Generated rrule: $savedRRule',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

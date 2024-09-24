// ignore_for_file: use_build_context_synchronously

import 'package:flutter_map_trip_planner/providers/route_provider.dart';
import 'package:flutter_map_trip_planner/screens/route_add_stop.dart';
import 'package:flutter_map_trip_planner/widgets/tags_auto_completion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:rrule_generator/rrule_generator.dart';
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:textfield_tags/textfield_tags.dart';
import '../providers/loading_provider.dart';
import '../utilities/location_functions.dart';
import '../utilities/rrule_date_calculator.dart';

class RouteCreationScreen extends StatefulWidget {
  RouteCreationScreen({
    required this.currentLocationData,
    required this.locationName,
    required this.selectedTags,
    required this.allTags,
    super.key,
  });

  late LocationData? currentLocationData;
  final String? locationName;
  final List<String> selectedTags;
  final List<String>? allTags;

  @override
  _RouteCreationScreenState createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  final List<TextEditingController> _stopNameControllers = [];
  List<Map<String, dynamic>> displayedUserAddedStops = [];
  List<Map<String, dynamic>> copy = [];
  final List<FocusNode> _stopFocusNodes = [FocusNode()];
  late flutterMap.MapController flutterMapController;
  List<LatLng> stops = [];
  List<String> displayTags = [];
  late TextfieldTagsController _textfieldTagsController;
  late flutterMap.Marker marker;

  @override
  void initState() {
    super.initState();
    _textfieldTagsController = TextfieldTagsController();
    displayTags = [...widget.selectedTags];
    displayTags.remove('All');
    marker = flutterMap.Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(widget.currentLocationData!.latitude!,
          widget.currentLocationData!.longitude!),
      child: const Icon(
        Icons.circle_sharp,
        color: Colors.blue,
        size: 16,
      ),
    );
    osm.GeoPoint geoPoint = osm.GeoPoint(
        latitude: widget.currentLocationData!.latitude!,
        longitude: widget.currentLocationData!.longitude!);
    _stopNameControllers.add(TextEditingController(text: widget.locationName));
    _stopControllers.add(TextEditingController(text: geoPoint.toString()));
    flutterMapController = flutterMap.MapController();
    stops.add(LatLng(widget.currentLocationData!.latitude!,
        widget.currentLocationData!.longitude!));
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
        _stopNameControllers.removeAt(index);
        _stopControllers.removeAt(index);
        stops.removeAt(index);
        _stopFocusNodes.removeAt(index);
      }
    });
  }

  Future<void> _fetchUserAddedStops() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<dynamic> userAddedStopsData =
          Provider.of<RouteProvider>(context, listen: false).userStops;
      print('USER ADDED STOPS : $userAddedStopsData');
      displayedUserAddedStops = userAddedStopsData.map((stopData) {
        return {
          'stop': stopData['stop'],
          'selectedPoint': stopData['selectedPoint'],
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
      displayedUserAddedStops.removeWhere((element) =>
          (element['selectedPoint'].toString().isEmpty ||
              element['selectedPoint'] == null));
      displayedUserAddedStops = displayedUserAddedStops;
    });
  }

  void _saveToFirebase(dynamic newRoute) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userID = user.uid;
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userID);

      await userRef.update({
        'routes': FieldValue.arrayUnion([
          newRoute,
        ]),
      });
    } else {
      print('User is not authenticated.');
    }
  }

  void _saveRoute() {
    String routeName = _routeNameController.text;
    List<String> stops =
        _stopControllers.map((controller) => controller.text).toList();
    print('STOPS -$stops');
    String? generatedRRule = generatedRRuleNotifier.value;
    String tag = '';
    List<String> tagsList = _textfieldTagsController.getTags! as List<String>;
    if (tagsList.isNotEmpty) {
      for (int i = 0; i < tagsList.length; i++) {
        if (i == tagsList.length - 1) {
          tag += tagsList[i];
          break;
        }
        tag += '${tagsList[i]},';
      }
    }
    // RegExp tagRegExp = RegExp(r'^[a-zA-Z]+(?:,[a-zA-Z]+)*$');
    // && !tagRegExp.hasMatch(tag.trim())
    if (tag.trim().isEmpty) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Invalid Tags'),
              content: const Text('Please enter a valid tag.'),
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

    if (routeName.trim().isNotEmpty && stops.length >= 2) {
      try {
        List<DateTime> dates = [];

        if (generatedRRule != null && generatedRRule.isNotEmpty) {
          RecurringDateCalculator dateCalculator =
              RecurringDateCalculator(generatedRRule);
          dates = dateCalculator.calculateRecurringDates();
        }

        var newRoute = {
          'routeID': DateTime.now().millisecondsSinceEpoch.toString(),
          'routeName': routeName,
          'stops': stops,
          'rrule': generatedRRule,
          'dates': dates.map((date) => date.toIso8601String()).toList(),
          'tags': tag,
        };
        Provider.of<RouteProvider>(context, listen: false).addRoute(newRoute);
        _saveToFirebase(newRoute);
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
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: TagsAutoCompletion(
                      textfieldTagsController: _textfieldTagsController,
                      allTags: widget.allTags,
                      displayTags: displayTags,
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
            const SizedBox(height: 16),
            const Text(
              'Stops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _stopNameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    key: ValueKey(index),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.reorder),
                        SizedBox(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: TextField(
                            readOnly: true,
                            // enabled: false,
                            controller: _stopNameControllers[index],
                            decoration: InputDecoration(
                                labelText: 'Stop ${index + 1}',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: () async {
                                    final selectedPoint =
                                        await showSimplePickerLocation(
                                      context: context,
                                      isDismissible: true,
                                      title: "Select Stop",
                                      textConfirmPicker: "pick",
                                      zoomOption: const ZoomOption(
                                        initZoom: 15,
                                      ),
                                      initPosition: parseGeoPoint(
                                          _stopControllers[index].text),
                                      radius: 15.0,
                                    );
                                    if (selectedPoint != null) {
                                      osm.GeoPoint geoPoint = selectedPoint;
                                      double latitude = geoPoint.latitude;
                                      double longitude = geoPoint.longitude;
                                      setState(() {
                                        stops[index] =
                                            LatLng(latitude, longitude);
                                      });
                                      _stopNameControllers[index].text =
                                          (await getPlaceName(
                                              latitude, longitude))!;
                                      _stopControllers[index].text =
                                          geoPoint.toString();
                                    }
                                  },
                                  icon: const Icon(Icons.gps_not_fixed),
                                )),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () => _removeStop(index),
                        ),
                      ],
                    ),
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex--;
                    }
                    TextEditingController stopNameController =
                        _stopNameControllers.removeAt(oldIndex);
                    TextEditingController stopController =
                        _stopControllers.removeAt(oldIndex);
                    LatLng stop = stops.removeAt(oldIndex);
                    _stopNameControllers.insert(newIndex, stopNameController);
                    _stopControllers.insert(newIndex, stopController);
                    stops.insert(newIndex, stop);
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fetchUserAddedStops();
                osm.GeoPoint selectedPoint = osm.GeoPoint(
                  latitude: widget.currentLocationData!.latitude!,
                  longitude: widget.currentLocationData!.longitude!,
                );
                String? updatedStopName;
                List<dynamic> data = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => RouteAddStopScreen(
                      currentLocationData: widget.currentLocationData!,
                      displayedUserAddedStops: displayedUserAddedStops,
                    ),
                  ),
                );
                updatedStopName = data[0]?.toString() ?? '';
                selectedPoint = data[1] as osm.GeoPoint;
                if (updatedStopName.trim().isEmpty) {
                  updatedStopName = await getPlaceName(
                    selectedPoint.latitude,
                    selectedPoint.longitude,
                  );
                }
                String updatedStop = selectedPoint.toString();
                setState(() {
                  _stopNameControllers
                      .add(TextEditingController(text: updatedStopName));
                  _stopControllers
                      .add(TextEditingController(text: updatedStop));
                  _stopFocusNodes.add(FocusNode());
                  stops.add(
                      LatLng(selectedPoint.latitude, selectedPoint.longitude));
                });
              }, // _addStop
              child: const Text('Add Stop'),
            ),
            Expanded(
              child: Stack(
                children: [
                  flutterMap.FlutterMap(
                    mapController: flutterMapController,
                    options: flutterMap.MapOptions(
                      initialCenter: LatLng(
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
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      flutterMap.MarkerLayer(
                        markers: [
                          for (int i = 0; i < stops.length; i++)
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
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          marker,
                        ],
                      ),
                    ],
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
                                .changeRouteCreationUpdateLocationState(true);
                            widget.currentLocationData =
                                await fetchCurrentLocation();
                            loadingProvider
                                .changeRouteCreationUpdateLocationState(false);
                            print(
                                'Updated Location  ==>  $widget.currentLocationData');
                            setState(() {
                              marker = flutterMap.Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(
                                    widget.currentLocationData!.latitude!,
                                    widget.currentLocationData!.longitude!),
                                child: const Icon(
                                  Icons.circle_sharp,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              );
                            });
                            flutterMapController.move(
                                LatLng(
                                  widget.currentLocationData!.latitude!,
                                  widget.currentLocationData!.longitude!,
                                ),
                                14);
                          },
                          child: loadingProvider.routeCreationUpdateLocation
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
            // ValueListenableBuilder<String?>(
            //   valueListenable: generatedRRuleNotifier,
            //   builder: (context, savedRRule, child) {
            //     return savedRRule != null
            //         ? Container(
            //             padding: const EdgeInsets.all(10),
            //             decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(10),
            //                 border: Border.all(
            //                   width: 1,
            //                   color: Colors.black,
            //                 )),
            //             child: Text(
            //               'Generated rrule: $savedRRule',
            //               style: const TextStyle(
            //                   fontSize: 16, fontWeight: FontWeight.bold),
            //             ),
            //           )
            //         : const SizedBox.shrink();
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

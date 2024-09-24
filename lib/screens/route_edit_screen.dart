// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:rrule_generator/rrule_generator.dart';
import 'package:textfield_tags/textfield_tags.dart';

import 'package:flutter_map_trip_planner/providers/loading_provider.dart';
import 'package:flutter_map_trip_planner/utilities/rrule_date_calculator.dart';
import 'package:flutter_map_trip_planner/widgets/tags_auto_completion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/route_provider.dart';
import '../utilities/location_functions.dart';

class RouteEditScreen extends StatefulWidget {
  const RouteEditScreen({
    super.key,
    required this.currentLocationData,
    required this.allTags,
    required this.routeName,
  });

  final String routeName;
  final LocationData? currentLocationData;
  final List<String>? allTags;

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  late TextEditingController _routeNameController;
  late List<TextEditingController> _stopControllers;
  late List<TextEditingController> _stopNameControllers;

  // late TextEditingController _tagsController;
  ValueNotifier<String?> generatedRRuleNotifier = ValueNotifier(null);
  late flutterMap.MapController mapController;
  String? savedRRule;
  String? routeId;
  late List<LatLng> userAddedStops;
  List<String> displayTags = [];
  late TextfieldTagsController _textfieldTagsController;

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController();
    _textfieldTagsController = TextfieldTagsController();
    _stopNameControllers = [];
    _stopControllers = [];
    userAddedStops = [];
    // _tagsController = TextEditingController();
    _fetchRouteDetails();
  }

  Future<bool> _fetchRouteDetails() async {
    try {
      // User? user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   print("user: $user");
      // DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
      //     .instance
      //     .collection('users')
      //     .doc(user.uid)
      //     .get();
      // List<dynamic> userRoutes = userDoc.get('routes') ?? [];
      List<dynamic> userRoutes =
          Provider.of<RouteProvider>(context, listen: false).userRoutes;
      var selectedRoute = userRoutes.firstWhere(
          (route) => route['routeName'] == widget.routeName,
          orElse: () => null);
      print('STOP GEO POINT TYPE -- ${selectedRoute['stops'][0]}');
      if (selectedRoute != null) {
        _routeNameController.text = selectedRoute['routeName'];
        displayTags.add(selectedRoute['tags']);
        // _tagsController.text = selectedRoute['tags'];
        generatedRRuleNotifier.value = selectedRoute['rrule'];
        List<dynamic> stops = selectedRoute['stops'];
        routeId = selectedRoute['routeID'];
        Provider.of<LoadingProvider>(context, listen: false)
            .changeEditRouteLoadingState(true);
        for (int i = 0; i < stops.length; i++) {
          double latitude =
              double.parse(stops[i].split(',')[0].split(':')[1].trim());
          double longitude = double.parse(
              stops[i].split(',')[1].split(':')[1].replaceAll('}', '').trim());
          userAddedStops.add(LatLng(latitude, longitude));
          String? locationName = await getPlaceName(latitude, longitude);
          _stopNameControllers.add(
            TextEditingController(text: locationName),
          );
          _stopControllers.add(
            TextEditingController(text: stops[i]),
          );
        }
        Provider.of<LoadingProvider>(context, listen: false)
            .changeEditRouteLoadingState(false);
      }
      // }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  void _saveToFirebase(User user, String tags, List<DateTime> dates,
      String? generatedRRule, String lastEdited) async {
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    // Fetch the user's data
    DocumentSnapshot<Object?> userDoc = await userRef.get();
    List<dynamic> userRoutes = userDoc.get('routes') ?? [];
    print('userRouts: $userRoutes');
    // Find the index of the existing route
    int existingRouteIndex = userRoutes
        .indexWhere((route) => route['routeName'] == widget.routeName);
    if (existingRouteIndex != -1) {
      // Update the route at the existing index
      userRoutes[existingRouteIndex] = {
        'routeID': routeId,
        'lastedited': DateTime.now().millisecondsSinceEpoch.toString(),
        'routeName': _routeNameController.text,
        'stops': _stopControllers.map((controller) => controller.text).toList(),
        'rrule': generatedRRule,
        'dates': dates.map((date) => date.toIso8601String()).toList(),
        'tags': tags,
      };

      await userRef.update({'routes': userRoutes});

      // showDialog(
      //   context: context,
      //   builder: (context) {
      //     return AlertDialog(
      //       title: const Text('Route Updated'),
      //       content: const Text('Route details updated successfully.'),
      //       actions: [
      //         TextButton(
      //           onPressed: () {
      //             Navigator.of(context).pop();
      //             Navigator.of(context).pop();
      //           },
      //           child: const Text('Ok'),
      //         ),
      //       ],
      //     );
      //   },
      // );
    }
  }

  void _updateRoute() {
    String routeName = _routeNameController.text;
    List<String> stops =
        _stopControllers.map((controller) => controller.text).toList();
    String tags = '';
    List<String> tagsList = _textfieldTagsController.getTags! as List<String>;
    if (tagsList.isNotEmpty) {
      for (int i = 0; i < tagsList.length; i++) {
        if (i == tagsList.length - 1) {
          tags += tagsList[i];
          break;
        }
        tags += '${tagsList[i]},';
      }
    }
    if (tags.trim().isEmpty) {
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
    if (!tagRegExp.hasMatch(tags.trim())) {
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
    if (routeName.trim().isNotEmpty && stops.length >= 2) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? generatedRRule = generatedRRuleNotifier.value;
          List<DateTime> dates = [];
          if (generatedRRule != null && generatedRRule.isNotEmpty) {
            RecurringDateCalculator dateCalculator =
                RecurringDateCalculator(generatedRRule);
            dates = dateCalculator.calculateRecurringDates();
          }
          String lastEdited = DateTime.now().millisecondsSinceEpoch.toString();
          _saveToFirebase(user, tags, dates, generatedRRule, lastEdited);
          Provider.of<RouteProvider>(context, listen: false)
              .updateRoute(routeName, {
            'routeID': routeId,
            'lastedited': lastEdited,
            'routeName': _routeNameController.text,
            'stops':
                _stopControllers.map((controller) => controller.text).toList(),
            'rrule': generatedRRule,
            'dates': dates.map((date) => date.toIso8601String()).toList(),
            'tags': tags,
          });

          Navigator.pop(context, true);
        } else {
          // print('Route not found');
        }
      } catch (e) {
        // print('Error updating route: $e');

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error!'),
              content: Text('Error updating route: $e'),
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

  void _editRRule() async {
    final rrule = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: SingleChildScrollView(
          child: RRuleGenerator(
            initialRRule: generatedRRuleNotifier.value ?? '',
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
      String updatedStop = selectedPoint.toString();
      double latitude =
          double.parse(updatedStop.split(',')[0].split(':')[1].trim());
      double longitude = double.parse(
          updatedStop.split(',')[1].split(':')[1].replaceAll('}', '').trim());
      String? locationName = await getPlaceName(latitude, longitude);
      setState(() {
        _stopNameControllers.add(TextEditingController(text: locationName));
        _stopControllers.add(TextEditingController(text: updatedStop));
        userAddedStops.add(LatLng(latitude, longitude));
      });
    }
  }

  void _removeStop(int index) {
    setState(() {
      if (index >= 0 && index < _stopControllers.length) {
        _stopNameControllers.removeAt(index);
        _stopControllers.removeAt(index);
        userAddedStops.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    // _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Route',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateRoute,
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.only(left: 10.0, right: 10, top: 16, bottom: 16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _routeNameController,
              decoration: const InputDecoration(
                labelText: 'Route Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TagsAutoCompletion(
                    textfieldTagsController: _textfieldTagsController,
                    allTags: widget.allTags,
                    displayTags: displayTags,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  onPressed: _editRRule,
                  child: const Text('Edit RRule'),
                ),
              ],
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
              child: Consumer<LoadingProvider>(
                builder: (BuildContext context, LoadingProvider loadingProvider,
                    Widget? child) {
                  return loadingProvider.editRouteLoading
                      ? Center(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TyperAnimatedText('Getting your stop names....'),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          itemCount: _stopNameControllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              key: ValueKey(index),
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Icon(Icons.reorder),
                                  Expanded(
                                    child: TextField(
                                      controller: _stopNameControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Stop ${index + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  if (index != 0)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle),
                                      onPressed: () => _removeStop(index),
                                    ),
                                ],
                              ),
                            );
                          },
                          onReorder: (int oldIndex, int newIndex) {
                            if (oldIndex < newIndex) {
                              newIndex--;
                            }
                            setState(() {
                              _stopNameControllers.insert(newIndex,
                                  _stopNameControllers.removeAt(oldIndex));
                              _stopControllers.insert(newIndex,
                                  _stopControllers.removeAt(oldIndex));
                              userAddedStops.insert(
                                  newIndex, userAddedStops.removeAt(oldIndex));
                            });
                          },
                        );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addStop,
              child: const Text('Add stop'),
            ),
            Expanded(
              child: flutterMap.FlutterMap(
                options: MapOptions(
                  initialCenter: userAddedStops[0],
                ),
                children: [
                  flutterMap.TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  flutterMap.MarkerLayer(
                    markers: [
                      for (int i = 0; i < userAddedStops.length; i++)
                        flutterMap.Marker(
                          point: userAddedStops[i],
                          child: Stack(
                            children: [
                              const Icon(Icons.location_on_sharp),
                              Positioned(
                                left: 0,
                                bottom: 1,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  flutterMap.PolylineLayer(
                    polylines: [
                      flutterMap.Polyline(
                        points: userAddedStops,
                        strokeWidth: 3,
                        color: Colors.blue,
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
                          ),
                        ),
                        child: Text(
                          'Generated rrule: $savedRRule',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

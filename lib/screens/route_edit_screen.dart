// ignore_for_file: use_build_context_synchronously

import 'package:driver_app/utilities/rrule_date_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:location/location.dart';
import 'package:rrule_generator/rrule_generator.dart';

class RouteEditScreen extends StatefulWidget {

  const RouteEditScreen({super.key, required this.currentLocationData, required this.routeName});

  final String routeName;
  final LocationData? currentLocationData;

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  late TextEditingController _routeNameController;
  late List<TextEditingController> _stopControllers;
  late TextEditingController _tagsController;
  ValueNotifier<String?> generatedRRuleNotifier = ValueNotifier(null);
  String? savedRRule;
  String? routeId;

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController();
    _stopControllers = [];
    _tagsController = TextEditingController();
    _fetchRouteDetails();
  }

  void _fetchRouteDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("user: $user");
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();
        List<dynamic> userRoutes = userDoc.get('routes') ?? [];
        var selectedRoute = userRoutes.firstWhere(
            (route) => route['routeName'] == widget.routeName,
            orElse: () => null);
        if (selectedRoute != null) {
          setState(() {
            _routeNameController.text = selectedRoute['routeName'];
            _tagsController.text = selectedRoute['tags'];
            generatedRRuleNotifier.value = selectedRoute['rrule'];
            List<dynamic> stops = selectedRoute['stops'];
            routeId = selectedRoute['routeID'];
            _stopControllers =
                stops.map((stop) => TextEditingController(text: stop)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching route details: $e');
    }
  }

  void _updateRoute() async {
    String routeName = _routeNameController.text;
    List<String> stops =
        _stopControllers.map((controller) => controller.text).toList();
    String? tags = _tagsController.text;
    String? generatedRRule = generatedRRuleNotifier.value;
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
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          List<DateTime> dates = [];

          if (generatedRRule != null && generatedRRule.isNotEmpty) {
            RecurringDateCalculator dateCalculator =
                RecurringDateCalculator(generatedRRule);
            dates = dateCalculator.calculateRecurringDates();
          }
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
              'stops': _stopControllers
                  .map((controller) => controller.text)
                  .toList(),
              'rrule': generatedRRule,
              'dates': dates.map((date) => date.toIso8601String()).toList(),
              'tags': _tagsController.text,
            };

            await userRef.update({'routes': userRoutes});

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Route Updated'),
                  content: const Text('Route details updated successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
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
          print('Route not found');
        }
      } catch (e) {
        print('Error updating route: $e');

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
      setState(() {
        _stopControllers.add(TextEditingController(text: updatedStop));
      });
    }
  }

  void _removeStop(int index) {
    setState(() {
      if (index >= 0 && index < _stopControllers.length) {
        _stopControllers.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    _tagsController.dispose();
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
        padding: const EdgeInsets.all(16.0),
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
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                border: OutlineInputBorder(),
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
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _stopControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _stopControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Stop ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
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
            ElevatedButton(
              onPressed: _addStop,
              child: const Text('Add stop'),
            ),
            ElevatedButton(
              onPressed: _editRRule,
              child: const Text('Edit RRule'),
            ),
          ],
        ),
      ),
    );
  }
}

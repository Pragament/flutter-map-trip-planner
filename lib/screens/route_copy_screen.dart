// ignore_for_file: use_build_context_synchronously

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_map_trip_planner/providers/loading_provider.dart';
import 'package:flutter_map_trip_planner/providers/route_provider.dart';
import 'package:flutter_map_trip_planner/utilities/rrule_date_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../utilities/location_functions.dart';

class RouteCopyScreen extends StatefulWidget {
  final String routeName;

  const RouteCopyScreen({super.key, required this.routeName});

  @override
  State<RouteCopyScreen> createState() => _RouteCopyScreenState();
}

class _RouteCopyScreenState extends State<RouteCopyScreen> {
  late TextEditingController _routeNameController;
  late List<TextEditingController> _stopControllers;
  late List<TextEditingController> _stopNameControllers;
  late TextEditingController _tagsController;
  ValueNotifier<String?> generatedRRuleNotifier = ValueNotifier(null);
  String? savedRRule;
  String? routeId;

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController();
    _stopControllers = [];
    _stopNameControllers = [];
    _tagsController = TextEditingController();
    _fetchRouteDetails();
  }

  void _fetchRouteDetails() async {
    try {
      List<dynamic> userRoutes =
          Provider.of<RouteProvider>(context, listen: false).userRoutes;
      var selectedRoute = userRoutes.firstWhere(
          (route) => route['routeName'].trim() == widget.routeName.trim(),
          orElse: () => null);
      if (selectedRoute != null) {
        print('ROUTE DETAILS');
        _routeNameController.text = selectedRoute['routeName'];
        _tagsController.text = selectedRoute['tags'];
        generatedRRuleNotifier.value = selectedRoute['rrule'];
        List<dynamic> stops = selectedRoute['stops'];
        routeId = selectedRoute['routeID'];
        Provider.of<LoadingProvider>(context, listen: false)
            .changeCopyRouteLoadingState(true);
        for (final stop in stops) {
          _stopControllers.add(TextEditingController(text: stop));
          double latitude =
              double.parse(stop.split(',')[0].split(':')[1].trim());
          double longitude = double.parse(
              stop.split(',')[1].split(':')[1].replaceAll('}', '').trim());
          String? locationName = await getPlaceName(latitude, longitude);
          _stopNameControllers.add(
            TextEditingController(text: locationName),
          );
        }
        Provider.of<LoadingProvider>(context, listen: false)
            .changeCopyRouteLoadingState(false);
      }
    } catch (e) {
      print('Error fetching route details: $e');
    }
  }

  Future<void> _saveToFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'routes': Provider.of<RouteProvider>(context, listen: false).userRoutes
      });
    } else {
      print('Route not found');
    }
  }

  void _updateRoute() {
    String newRouteName = _routeNameController.text;
    String? generatedRRule = generatedRRuleNotifier.value;
    List<DateTime> dates = [];
    try {
      if (generatedRRule != null && generatedRRule.isNotEmpty) {
        RecurringDateCalculator dateCalculator =
            RecurringDateCalculator(generatedRRule);
        dates = dateCalculator.calculateRecurringDates();
      }

      List<dynamic> userRoutes =
          Provider.of<RouteProvider>(context, listen: false).userRoutes;

      // Check if the new route name is different from the existing one
      bool isDifferentRouteName = userRoutes
          .every((route) => route['routeName'] != newRouteName.trim());

      if (!isDifferentRouteName) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error!'),
              content: const Text(
                  'Route name already exists. Please choose a different name.'),
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
        return; // Exit the function if route name already exists
      }

      // Create a new route object
      var newRoute = {
        'routeID': DateTime.now().millisecondsSinceEpoch.toString(),
        'routeName': newRouteName,
        'stops': _stopControllers.map((controller) => controller.text).toList(),
        'rrule': generatedRRule,
        'dates': dates.map((date) => date.toIso8601String()).toList(),
        'tags': _tagsController.text,
      };

      // Add the new route to the list of user routes
      Provider.of<RouteProvider>(context, listen: false).addRoute(newRoute);

      // Update the user document with the new routes list
      _saveToFirebase();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Route Updated'),
            content: const Text('New route added successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/allroutes', (route) => false);
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
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
          'Copy Route',
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
              enabled: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              enabled: false,
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
            Consumer<LoadingProvider>(
                builder: (context, loadingProvider, child) {
              print('LOADING STATE : ${loadingProvider.copyRouteLoading}');
              return Expanded(
                child: loadingProvider.copyRouteLoading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              'Getting your stop names ...',
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _stopNameControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    enabled: false,
                                    controller: _stopNameControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Stop ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              );
            }),
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
                          'Generated rrule: ${generatedRRuleNotifier.value}',
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

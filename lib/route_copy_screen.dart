// ignore_for_file: use_build_context_synchronously

import 'package:driver_app/rrule_date_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteCopyScreen extends StatefulWidget {
  final String routeName;

  const RouteCopyScreen({required this.routeName});

  @override
  _RouteCopyScreenState createState() => _RouteCopyScreenState();
}

class _RouteCopyScreenState extends State<RouteCopyScreen> {
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
    String newRouteName = _routeNameController.text;
    String? generatedRRule = generatedRRuleNotifier.value;
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
          'stops':
              _stopControllers.map((controller) => controller.text).toList(),
          'rrule': generatedRRule,
          'dates': dates.map((date) => date.toIso8601String()).toList(),
          'tags': _tagsController.text,
        };

        // Add the new route to the list of user routes
        userRoutes.add(newRoute);

        // Update the user document with the new routes list
        await userRef.update({'routes': userRoutes});

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
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/allroutes', (route) => false);
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
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
                            enabled: false,
                            controller: _stopControllers[index],
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

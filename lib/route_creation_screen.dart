// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrule_generator/rrule_generator.dart';
import 'search_example.dart';
import 'rrule_date_calculator.dart';

class RouteCreationScreen extends StatefulWidget {
  @override
  _RouteCreationScreenState createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _stopnameController = TextEditingController();
  List<Map<String, dynamic>> displayedUserAddedStops = [];
  List<Map<String, dynamic>> copy = [];
  final List<FocusNode> _stopFocusNodes = [FocusNode()];

  void _addStop() async {
    final selectedPoint = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: ((context) => const LocationAppExample()),
      ),
    );
    if (selectedPoint != null) {
      String updatedStop = selectedPoint.toString();
      setState(() {
        _stopControllers.add(TextEditingController(text: updatedStop));
        _stopFocusNodes.add(FocusNode());
      });
    }
  }

  @override
  void initState() {
    super.initState();
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

        _stopControllers.removeAt(index);
        _stopFocusNodes.removeAt(index);
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
                displayedUserAddedStops.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        children: displayedUserAddedStops.map((stop) {
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
                                    _stopnameController.text = stop['stop'];
                                    _stopControllers.add(
                                      TextEditingController(
                                          text: selectedPoint),
                                    );
                                    // Remove the added stop from displayedUserAddedStops
                                    displayedUserAddedStops.remove(stop);

                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
                            readOnly: true,
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
            ElevatedButton(
              onPressed: _addStop,
              child: const Text('Add Stop'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _scheduleRoute,
                  child: const Text('Schedule Route'),
                ),
                ElevatedButton(
                  onPressed: _saveRoute,
                  child: const Text('Save Route'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

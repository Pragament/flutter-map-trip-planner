// import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'route_creation_screen.dart';
// import 'local_notifications.dart';
import '../screens/route_display_screen.dart';

class RouteTable extends StatefulWidget {
  const RouteTable({Key? key, List<Map<String, dynamic>>? routes});

  @override
  State<RouteTable> createState() => _RouteTableState();
}

class _RouteTableState extends State<RouteTable> {
  List<Map<String, dynamic>>? _routes;

  Future<List<Map<String, dynamic>>> _fetchRoutes() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      List<Map<String, dynamic>> routes = List<Map<String, dynamic>>.from(
          userDoc.get('routes') ?? [] as List<Map<String, dynamic>>);
      return routes;
    }
    return [];
  }

  @override
  void initState() {
    // listenToNotifications();
    super.initState();
    _init();
  }

  Future<void> _init() async {
    List<Map<String, dynamic>> routes = await _fetchRoutes();
    setState(() {
      _routes = routes;
    });
    // _sendNotificationIfNearestDateIsToday();
  }

  // void _sendNotificationIfNearestDateIsToday() {
  //   print('Checking');
  //   if (_routes != null) {
  //     DateTime now = DateTime.now();
  //     DateTime nearestDate = DateTime(9999);
  //     Map<String, dynamic>? nearestRouteData;
  //     String? routename;

  //     for (var route in _routes!) {
  //       Map<String, dynamic> routeData = route;
  //       List<String> dates = List<String>.from(routeData['dates'] ?? []);
  //       for (var dateStr in dates) {
  //         DateTime date = DateTime.parse(dateStr).toLocal();
  //         if (date.isAfter(now) && date.isBefore(nearestDate)) {
  //           nearestDate = date;
  //           nearestRouteData = routeData;
  //           routename = routeData['routeName'];
  //         }
  //       }
  //     }

  //     if (nearestDate.isBefore(DateTime(9999)) &&
  //         nearestDate.year == now.year &&
  //         nearestDate.month == now.month &&
  //         nearestDate.day == now.day) {
  //       // Nearest date is today, send a notification
  //       String payloadString = jsonEncode(nearestRouteData);
  //       LocalNotifications.showSimpleNotification(
  //         title: 'Route Reminder',
  //         body: 'Today is the day for your route $routename',
  //         payload: payloadString,
  //       );
  //     }
  //   }
  // }

  //listen to notifications
  // listenToNotifications() {
  //   print("Listening to notification");
  //   LocalNotifications.onClickNotification.stream.listen((event) {
  //     Map<String, dynamic> payloadData = jsonDecode(event);
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => RouteDetailsScreen(
  //           route: payloadData,
  //         ),
  //       ),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Routes - ListView',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: _routes != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _routes!.length,
                itemBuilder: (context, index) {
                  var route = _routes![index];
                  List<String> dates = List<String>.from(route['dates'] ?? []);
                  String istDateTimeString = "Date not available";

                  if (dates.isNotEmpty) {
                    DateTime now = DateTime.now();
                    DateTime nearestDate = DateTime(9999);

                    for (var dateStr in dates) {
                      DateTime date = DateTime.parse(dateStr);
                      if (date.isAfter(now) && date.isBefore(nearestDate)) {
                        nearestDate = date;
                      }
                    }

                    if (nearestDate.isBefore(DateTime(9999))) {
                      DateTime istDate = nearestDate
                          .add(const Duration(hours: 5, minutes: 30));
                      String formattedDate =
                          "${istDate.day}-${istDate.month}-${istDate.year}";
                      String formattedTime =
                          "${istDate.hour}:${istDate.minute}";
                      istDateTimeString = "$formattedDate $formattedTime";
                    }
                  }

                  return Card(
                    child: ListTile(
                      title: Text(
                        route['routeName'] ?? "No routes found!",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                          route['rrule'] != null && route['rrule'].isNotEmpty
                              ? "Next reminder is at: $istDateTimeString"
                              : "This route was not scheduled!"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RouteDetailsScreen(route: route),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.amber,
      //   child: const Icon(
      //     Icons.add,
      //     color: Colors.white,
      //   ),
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => RouteCreationScreen(),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

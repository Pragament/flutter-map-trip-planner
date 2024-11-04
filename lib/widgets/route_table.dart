// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/screens/route_creation_screen.dart';
import 'package:location/location.dart';

import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../screens/route_display_screen.dart';

class RouteTable extends StatefulWidget {
  const RouteTable({
    super.key,
    List<Map<String, dynamic>>? routes,
  });

  @override
  State<RouteTable> createState() => _RouteTableState();
}

class _RouteTableState extends State<RouteTable> {
  List<dynamic>? _routes;
  late LocationData samplelLocationData;

  void _fetchRoutes() {
    _routes = Provider.of<RouteProvider>(context, listen: false).userRoutes;
  }

  @override
  void initState() {
    // listenToNotifications();
    super.initState();
    _fetchRoutes();
    // Map<String, dynamic> sampleLocationMap = {
    //   'latitude': 37.7749,
    //   'longitude': -122.4194,
    //   'accuracy': 5.0,
    //   'altitude': 10.0,
    //   'speed': 0.0,
    //   'speed_accuracy': 0.0,
    //   'heading': 0.0,
    //   'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
    //   'isMock': false,
    //   'verticalAccuracy': 5.0,
    //   'headingAccuracy': 1.0,
    //   'elapsedRealtimeNanos': 0.0,
    //   'elapsedRealtimeUncertaintyNanos': 0.0,
    //   'satelliteNumber': 0,
    //   'provider': 'gps',
    // };

    // samplelLocationData = LocationData.fromMap(sampleLocationMap);
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
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        title: const Text(
          'Routes - ListView',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          // TODO create a form creation screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //       builder: (context) => RouteCreationScreen(
          //             currentLocationData:
          //                 samplelLocationData, // Replace with actual data
          //             locationName:
          //                 "sample location data", // Replace with actual data
          //             selectedTags: [
          //               'tag1',
          //               'tag2'
          //             ], // Replace with actual data
          //             allTags: ['tag1', 'tag2', 'tag3'],
          //           )),
          // );
        },
      ),
    );
  }
}

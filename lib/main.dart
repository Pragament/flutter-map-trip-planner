import 'dart:async';
import 'dart:convert';

// import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/models/event.dart';
import 'package:flutter_map_trip_planner/providers/event_provider.dart';
import 'package:flutter_map_trip_planner/providers/filters_provider.dart';
import 'package:flutter_map_trip_planner/providers/loading_provider.dart';
import 'package:flutter_map_trip_planner/providers/location_provider.dart';
import 'package:flutter_map_trip_planner/providers/route_provider.dart';
import 'package:flutter_map_trip_planner/providers/user_info_provider.dart';
import 'package:flutter_map_trip_planner/screens/all_events.dart';
// import 'package:flutter_map_trip_planner/route_details_fetcher.dart';
import 'package:flutter_map_trip_planner/screens/all_routes.dart';
import 'package:flutter_map_trip_planner/screens/login.dart';
import 'package:flutter_map_trip_planner/screens/overlay_layout.dart';
import 'package:flutter_map_trip_planner/screens/route_display_screen.dart';
import 'package:flutter_map_trip_planner/widgets/local_notifications.dart';
import 'package:flutter_map_trip_planner/widgets/route_table.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await Permission.notification.isGranted
      .then((value) => LocalNotifications.init());
  // Get the saved login timestamp from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? loginTimestamp = prefs.getString('login_timestamp');

  List<Map<String, dynamic>> routes =
      await _fetchRoutes(); // Assuming _fetchRoutes is defined in route_table.dart
  List<Map<String, dynamic>> userEvents = await _fetchEvents();

  // Function to send notification if nearest date is today
  void sendNotificationIfNearestDateIsToday() {
    debugPrint('Checking');
    DateTime now = DateTime.now();
    DateTime nearestDate = DateTime(9999);
    Map<String, dynamic>? nearestRouteData;
    String? routename;

    for (var route in routes) {
      Map<String, dynamic> routeData = route;
      List<String> dates = List<String>.from(routeData['dates'] ?? []);
      for (var dateStr in dates) {
        DateTime date = DateTime.parse(dateStr).toLocal();
        if (date.isAfter(now) && date.isBefore(nearestDate)) {
          nearestDate = date;
          nearestRouteData = routeData;
          routename = routeData['routeName'];
        }
      }
    }

    if (nearestDate.isBefore(DateTime(9999)) &&
        nearestDate.year == now.year &&
        nearestDate.month == now.month &&
        nearestDate.day == now.day) {
      // Nearest date is today, send a notification
      String payloadString = jsonEncode(nearestRouteData);
      LocalNotifications.showSimpleNotification(
        title: 'Route Reminder',
        body: 'Today is the day for your route $routename',
        payload: payloadString,
      );
    }
  }

  // Check if the user is already signed in within the last 5 days
  bool isSignedInWithin5Days = false;
  if (loginTimestamp != null) {
    DateTime lastLogin = DateTime.parse(loginTimestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(lastLogin);
    if (difference.inDays <= 5) {
      isSignedInWithin5Days = true;
      sendNotificationIfNearestDateIsToday();
    }
  }

  // if (!await FlutterOverlayWindow.isPermissionGranted()) {
  //   await FlutterOverlayWindow.requestPermission();
  // }

  runApp(
    MyApp(isSignedInWithin5Days, routes, userEvents),
  );
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.green,
        child: OverlayLayout(),
      ),
    ),
  );
}

// Future<List<Map<String, dynamic>>> _fetchRoutes() async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user != null) {
//     DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
//         .instance
//         .collection('users')
//         .doc(user.uid)
//         .get();
//     List<Map<String, dynamic>> routes = List<Map<String, dynamic>>.from(
//         userDoc.get('routes') ?? [] as List<Map<String, dynamic>>);
//     return routes;
//   }
//   return [];
// }

Future<List<Map<String, dynamic>>> _fetchRoutes() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Step 1: Fetch the user's document
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Step 2: Get the list of route IDs
    List<dynamic> routeIds = userDoc.get('routeIds') ?? [];

    // Step 3: Initialize an empty list to hold the routes
    List<Map<String, dynamic>> routes = [];

    // Step 4: Fetch each route from the 'routes' collection using the route IDs
    for (var routeId in routeIds) {
      DocumentSnapshot<Map<String, dynamic>> routeDoc = await FirebaseFirestore
          .instance
          .collection('routes')
          .doc(routeId)
          .get();

      if (routeDoc.exists) {
        routes.add(routeDoc.data()!); // Add the route data to the list
      }
    }

    // Step 5: Return the list of routes
    return routes;
  }

  return [];
}

Future<List<Map<String, dynamic>>> _fetchEvents() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Fetch user document
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Get list of event IDs
      List<dynamic> eventIds = userDoc.get('eventIds') ?? [];

      // Fetch events in parallel using Futures
      List<DocumentSnapshot<Map<String, dynamic>>> eventDocs =
          await Future.wait(
        eventIds.map((eventId) {
          return FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get();
        }),
      );

      // Filter out non-existing documents and convert to map
      List<Map<String, dynamic>> events = eventDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data()!)
          .toList();

      return events;
    } catch (e) {
      // Handle errors and return an empty list if something goes wrong
      print('Error fetching user events: $e');
      return [];
    }
  } else {
    try {
      // Fetch all events for non-logged-in users
      QuerySnapshot<Map<String, dynamic>> allEventsSnapshot =
          await FirebaseFirestore.instance.collection('events').get();

      // Convert query snapshot to a list of maps
      List<Map<String, dynamic>> allEvents =
          allEventsSnapshot.docs.map((doc) => doc.data()).toList();

      return allEvents;
    } catch (e) {
      // Handle errors and return an empty list
      print('Error fetching all events: $e');
      return [];
    }
  }
}


class MyApp extends StatefulWidget {
  final bool isSignedInWithin5Days;
  final List<Map<String, dynamic>>? routes;
  final List<Map<String, dynamic>>? userEvents;

  const MyApp(this.isSignedInWithin5Days, this.routes, this.userEvents,
      {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //listen to notifications
  listenToNotifications() {
    debugPrint("Listening to notification");
    LocalNotifications.onClickNotification.stream.listen((event) {
      Map<String, dynamic> payloadData = jsonDecode(event);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteDetailsScreen(
            route: payloadData,
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    listenToNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => LoadingProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RouteProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UserInfoProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FiltersProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => LocationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Trip Planner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
          useMaterial3: true,
        ),
        home: widget.isSignedInWithin5Days
            ? AllRoutesMapScreen(
                userRoutes: widget.routes, userEvents: widget.userEvents)
            : PhoneAuthScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/routetable': (context) => RouteTable(routes: widget.routes),
          '/login': (context) => PhoneAuthScreen(),
          '/allroutes': (context) => AllRoutesMapScreen(
                userRoutes: Provider.of<RouteProvider>(context, listen: false)
                    .userRoutes,
                userEvents:
                    Provider.of<EventProvider>(context, listen: false).events,
              ),
        },
      ),
    );
  }
}

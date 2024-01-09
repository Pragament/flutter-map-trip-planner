import 'dart:async';
import 'dart:convert';

import 'package:driver_app/screens/overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'firebase_options.dart';
import 'package:driver_app/providers/loading_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permission_handler/permission_handler.dart';
import 'screens/login.dart';
import 'widgets/local_notifications.dart';
import 'widgets/route_table.dart';
import 'screens/all_routes.dart';
import 'screens/route_display_screen.dart';

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

  // Function to send notification if nearest date is today
  void sendNotificationIfNearestDateIsToday() {
    print('Checking');
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

  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.requestPermission();
  }

  runApp(
    MyApp(isSignedInWithin5Days, routes),
  );
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.yellow[200],     // teal, green, blue, deepPurple
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Padding(
                 padding: EdgeInsets.only(left: 10.0),
                 child: Text(
                   'Nearest Stop :',
                   style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                 ),
               ),
               IconButton(
                  onPressed: FlutterOverlayWindow.closeOverlay,
                  icon: Icon(Icons.cancel_rounded, size: 25,),
                ),
             ],
           ),
           Expanded(child: OverLayScreen()),
        ],
        ),
      ),
    ),
  );
}

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

class MyApp extends StatefulWidget {
  final bool isSignedInWithin5Days;
  final List<Map<String, dynamic>>? routes;

  const MyApp(this.isSignedInWithin5Days, this.routes, {Key? key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //listen to notifications
  listenToNotifications() {
    print("Listening to notification");
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
      ],
      child: MaterialApp(
        title: 'Driver App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple,),
          useMaterial3: true,
        ),
        home: widget.isSignedInWithin5Days
            ? const AllRoutesMapScreen()
            : PhoneAuthScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/routetable': (context) => RouteTable(routes: widget.routes),
          '/login': (context) => PhoneAuthScreen(),
          '/allroutes': (context) => const AllRoutesMapScreen(),
        },
      ),
    );
  }
}

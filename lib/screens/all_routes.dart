import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_map_trip_planner/miscellaenous/add_route_to_firebase.dart';
import 'package:flutter_map_trip_planner/miscellaenous/save_user_location.dart';
import 'package:flutter_map_trip_planner/providers/location_provider.dart';
import 'package:flutter_map_trip_planner/screens/route_add_stop.dart';
import 'package:flutter_map_trip_planner/widgets/filter_item.dart';
import 'package:flutter/material.dart';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_map_trip_planner/providers/filters_provider.dart';
import 'package:flutter_map_trip_planner/providers/loading_provider.dart';
import 'package:flutter_map_trip_planner/providers/route_provider.dart';
import 'package:flutter_map_trip_planner/providers/user_info_provider.dart';
import 'package:flutter_map_trip_planner/screens/add_stop.dart';
import 'package:flutter_map_trip_planner/screens/login.dart';
import 'package:flutter_map_trip_planner/screens/route_creation_screen.dart';
import 'package:flutter_map_trip_planner/screens/route_edit_screen.dart';
import 'package:flutter_map_trip_planner/screens/route_copy_screen.dart';
import 'package:flutter_map_trip_planner/utilities/rrule_date_calculator.dart';
import 'package:flutter_map_trip_planner/widgets/route_table.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;

import '../utilities/location_functions.dart';
import '../utilities/rrule_parser.dart';

class AllRoutesMapScreen extends StatefulWidget {
  AllRoutesMapScreen({required this.userRoutes, super.key});

  List<dynamic>? userRoutes;

  @override
  State<AllRoutesMapScreen> createState() => _AllRoutesMapScreenState();
}

class _AllRoutesMapScreenState extends State<AllRoutesMapScreen>
    with WidgetsBindingObserver {
  late MapController flutterMapController;

  // LocationData? currentLocation;
  String? selectedRouteId;
  String? centeredRouteId;

  bool hasSkippedLogin = false;


  // List<Map<String, dynamic>> filteredUserStops = [];
  List<dynamic> filteredUserRoutes = [];
  Map<String, List<LatLng>> filteredRouteStopsMap = {};
  late List<String> selectedTags;
  List<dynamic> displayedRoutes = [];
  List<String> allTagsList = ['All'];
  List<bool> isSelected = [];
  int previousIndex = 0;
  Future<List<String>>? futureList;
  String? locationName;

  // Future<bool>? getLocation;
  String nextStop = 'Getting your location...';
  late StreamSubscription userCurrentLocation;
  late TileLayer tileLayer;
  bool stopsFilter = false;
  Location location = Location();
  int stop = 0;
  late StreamSubscription<LocationData> locationStreamSubscription;
  late Marker marker;
  List<TextEditingController> filterStopsController = [];

  @override
  void initState() {
    super.initState();
    // location.changeSettings(interval: 3000);
    // location.enableBackgroundMode();
    selectedTags = allTagsList;
    tileLayer = TileLayer(
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    );
    flutterMapController = MapController();
    // getLocation = _fetchCurrentLocationName();
    isSelected.add(true);
    futureList = _fetchAllStops();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // location.changeSettings(interval: 3000);
      // location.enableBackgroundMode();
      askForContinousLocation();
      askForDisplayOverApps();
    });
    _checkSkipLoginState();

  }

  Future<void> _checkSkipLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      hasSkippedLogin = prefs.getBool('skip_login') ?? false; // Default to false if not set
    });
  }

  void askForContinousLocation() async {
    bool isEne = await location.isBackgroundModeEnabled();
    debugPrint('apk: backgroundenabled: $isEne');
    if (!await location.isBackgroundModeEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trying to get background location!'),
          duration: Durations.short2,
        ),
      );
      location.enableBackgroundMode();
    }
  }

  void askForDisplayOverApps() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_in_picture,
                  size: 32,
                  color: Colors.green,
                ),
                Text(
                  'Allowing our app to display over other apps will enhance your user experience by providing timely notifications and interactive features. Would you like to enable this permission?',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Deny'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FlutterOverlayWindow.requestPermission();
                },
                child: const Text('Allow'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _stopsFilter(final filteredStops) async {
    filterStopsController = [];
    for (final item in filteredStops) {
      String? name = await getPlaceName(item.latitude, item.longitude);
      filterStopsController.add(TextEditingController(text: name));
    }
  }

  Future<bool> _fetchCurrentLocationName(LocationData currentLocation) async {
    // Provider.of<LoadingProvider>(context, listen: false)
    //     .changeLocationLoadingState(true);
    debugPrint('Location Updated');
    debugPrint("${DateTime.now().second}");
    currentLocation = await fetchCurrentLocation() ??
        LocationData.fromMap({'latitude': 37.4219983, 'longitude': -122.084});
    locationName = await getPlaceName(
        currentLocation.latitude!, currentLocation.longitude!);
    Provider.of<LoadingProvider>(context, listen: false)
        .changeLocationLoadingState(false);
    Provider.of<LocationProvider>(context, listen: false)
        .updateCurrentLocation(currentLocation);
    return true;
  }

  Future<List<String>> _fetchAllStops() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (context.mounted) {
        Provider.of<UserInfoProvider>(context, listen: false).assignUserInfo(
          userName: userDoc.get('name'),
          dateOfBirth: userDoc.get('dateofbirth'),
          phoneNumber: userDoc.get(
            'phoneNumber',
          ),
        );
      }
      List<dynamic> userAddedStopsData = [];
      if (userDoc.get('useraddedstops').runtimeType != String) {
        userAddedStopsData = userDoc.get('useraddedstops');
      }
      List<Map<String, dynamic>> userAddedStops =
          userAddedStopsData.map((stopData) {
        // Extract latitude and longitude from the selectedpoint string
        String selectedPointString = stopData['selectedPoint'];
        if (selectedPointString.isNotEmpty) {
          double latitude = double.parse(
              selectedPointString.split(',')[0].split(':')[1].trim());
          double longitude = double.parse(selectedPointString
              .split(',')[1]
              .split(':')[1]
              .replaceAll('}', '')
              .trim());
          String stopName = stopData['stop'];
          String tags1 = stopData['tags'];
          return {
            'stop': stopName,
            'tags': tags1,
            'selectedPoint': LatLng(latitude, longitude),
          };
        }
        return <String, String>{};
      }).toList();
      userAddedStops.removeWhere((element) => element.isEmpty);
      if (context.mounted) {
        Provider.of<RouteProvider>(context, listen: false)
            .assignStops(userAddedStops);
        // Get all tags from routes and user-added stops
        Set<String> allTags = <String>{};
        allTags.add('All');
        Provider.of<RouteProvider>(context, listen: false)
            .assignRoutes(widget.userRoutes!);
        Provider.of<RouteProvider>(context, listen: false)
            .routeStops(widget.userRoutes!);
        List<dynamic>? userRoutes =
            Provider.of<RouteProvider>(context, listen: false).userRoutes;
        for (var route in userRoutes) {
          List<String> tags = route['tags'].split(',');
          allTags.addAll(tags);
        }

        for (var stop in userAddedStops) {
          allTags.addAll(stop['tags'].split(','));
        }

        allTagsList = allTags.toList();
        allTagsList.removeWhere((element) => element.isEmpty);

        for (int i = 1; i < allTagsList.length; i++) {
          isSelected.add(false);
        }
      }
    }
    return allTagsList;
  }

  Color _getRouteColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.amber,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  void _deleteRoute({required String routeName}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userID = user.uid;

        // Step 1: Get the user's document to fetch the routeIds
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userID);
        // DocumentSnapshot userSnapshot = await userRef.get();
        // List<dynamic> routeIds = userSnapshot.get('routeIds') ?? [];

        // Step 2: Find the route in the 'routes' collection based on the routeName
        QuerySnapshot routeQuery = await FirebaseFirestore.instance
            .collection('routes')
            .where('routeName', isEqualTo: routeName)
            .get();

        if (routeQuery.docs.isNotEmpty) {
          String routeId = routeQuery.docs.first.id;

          // Step 3: Delete the route from the 'routes' collection
          await FirebaseFirestore.instance
              .collection('routes')
              .doc(routeId)
              .delete();

          // Step 4: Remove the routeId from the user's document
          await userRef.update({
            'routeIds': FieldValue.arrayRemove([routeId]),
          });

          debugPrint('Route deleted successfully.');
        } else {
          debugPrint('Route not found in the routes collection.');
        }
      } else {
        debugPrint('User is not authenticated.');
      }
    } catch (e) {
      debugPrint('Error deleting route: $e');

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error!'),
            content: Text('Error deleting route: $e'),
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

  String _constructMapUrl(List<LatLng> stops) {
    String baseUrl = "https://www.google.com/maps/dir/";

    String stopsString = stops.map((stop) {
      return "${stop.latitude},${stop.longitude}";
    }).join("/");
    // print('$baseUrl$stopsString/');
    return "$baseUrl$stopsString/";
  }

  void _startNavigation(List<LatLng> stops) async {
    String mapUrl = _constructMapUrl(stops);
    if (!await launchUrlString(
      mapUrl,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch url $mapUrl');
    }
  }

  Future<void> _clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> uploadFileToFirebaseStorage(File file, String routeName) async {
    User? user = FirebaseAuth.instance.currentUser;
    String userID = user!.uid;
    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('$userID/routes/$routeName.json')
          .putFile(file);
    } catch (e) {
      // print('Error uploading file: $e');
    }
  }

  Future<String?> getFirebaseStorageDownloadUrl(String routeName) async {
    User? user = FirebaseAuth.instance.currentUser;
    String userID = user!.uid;
    try {
      String downloadUrl = await firebase_storage.FirebaseStorage.instance
          .ref('$userID/routes/$routeName.json')
          .getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // print('Error getting download URL: $e');
      return null;
    }
  }

  Map<String, dynamic> fetchRouteDetails(String routeName) {
    List<dynamic> routes =
        Provider.of<RouteProvider>(context, listen: false).userRoutes;
    int indexToFetch =
        routes.indexWhere((route) => route['routeName'] == routeName);
    if (indexToFetch >= 0) {
      Map<String, dynamic> route = routes[indexToFetch];
      // print('route: $route');
      return route;
    }
    return {};
  }

  Future<void> encodeAndShareRoute(String routeName) async {
    Map<String, dynamic> routeDetails = fetchRouteDetails(routeName);
    String jsonData = jsonEncode(routeDetails);
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$routeName.json');
    await file.writeAsString(jsonData);

    await uploadFileToFirebaseStorage(file, routeName);

    String? downloadUrl = await getFirebaseStorageDownloadUrl(routeName);

    if (downloadUrl != null) {
      Share.share('Check out this route: $downloadUrl');
    } else {
      // print('Error: Could not get download URL');
    }
  }

  Future<void> _importRoute() async {
    String? url = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController urlController = TextEditingController();
        return AlertDialog(
          title: const Text('Import Route'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'Route URL',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(urlController.text);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (url != null && url.isNotEmpty) {
      try {
        http.Response response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          Map<String, dynamic> routeData = json.decode(response.body);

          if (context.mounted) {
            Provider.of<RouteProvider>(context, listen: false)
                .addRoute(routeData);
          }

          // Add the route data to Firestore
          addImportedRouteToFirebase(routeData);

          // Show success dialog
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Route Imported'),
                  content: const Text('Route imported successfully.'),
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
          throw Exception('Error downloading route data');
        }
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Error importing route: $e'),
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
    }
  }

  void cancelLocationSubscription() {
    locationStreamSubscription.cancel();
  }

  Future<void> getNextStop(List<LatLng> stops, String rtName) async {
    List<LatLng> routeStops = List.from(stops);
    location.enableBackgroundMode(enable: true);

    QuerySnapshot routeQuery = await FirebaseFirestore.instance
        .collection('routes')
        .where('routeName', isEqualTo: rtName)
        .get();

    final routeId = routeQuery.docs.first.id;

    locationStreamSubscription.onData((userLocation) async {
      await saveUserLocationToFirebase(
          LatLng(userLocation.latitude!, userLocation.longitude!), routeId);
      double minDistance = double.infinity;
      int index = 0;

      debugPrint(
          'apk: Current user location: (${userLocation.latitude}, ${userLocation.longitude})');
      await FlutterOverlayWindow.shareData(
        {
          'routeId': routeId,
          'nextStop':
              'User Location: ${userLocation.latitude}, ${userLocation.longitude}',
        },
      );

      // Calculate the nearest stop
      for (int i = 0; i < routeStops.length; i++) {
        double distance = calculateDistance(
            LatLng(userLocation.latitude!, userLocation.longitude!),
            routeStops[i]);

        debugPrint('apk: Calculated distance to stop ${i + 1}: $distance');
        await FlutterOverlayWindow.shareData({
          'routeId': routeId,
          'nextStop': 'Distance to Stop ${i + 1}: $distance',
        });

        if (distance < minDistance) {
          index = i;
          minDistance = distance;
        }
      }

      LatLng nearestStop = routeStops[index];
      routeStops.removeAt(index);
      routeStops.insert(0, nearestStop);

      // Fetch the nearest stop name
      if (routeStops.isNotEmpty) {
        String? locationName =
            await getPlaceName(routeStops[0].latitude, routeStops[0].longitude);
        debugPrint('apk: locationName from outside is: $locationName');
        // Send nearest stop info
        await FlutterOverlayWindow.shareData({
          'routeId': routeId,
          'nextStop': 'Nearest Stop: $locationName',
        });

        if (nextStop != locationName) {
          nextStop = locationName!;
          debugPrint('apk: Updated nearest stop: $locationName');
          // Send updated next stop
          await FlutterOverlayWindow.shareData({
            'routeId': routeId,
            'nextStop': 'Next Stop: $locationName',
          });
        }
      }

      // Define the boundaries for the current stop
      double stopMinLatitude = routeStops[0].latitude - 0.002;
      double stopMaxLatitude = routeStops[0].latitude + 0.002;
      double stopMinLongitude = routeStops[0].longitude - 0.002;
      double stopMaxLongitude = routeStops[0].longitude + 0.002;

      debugPrint(
          'apk: Stop boundaries - Lat: [$stopMinLatitude, $stopMaxLatitude], Lon: [$stopMinLongitude, $stopMaxLongitude]');
      // await FlutterOverlayWindow.shareData(
      //     'Stop Boundaries: Lat [$stopMinLatitude, $stopMaxLatitude], Lon [$stopMinLongitude, $stopMaxLongitude]');

      // Check if user has reached the stop
      if (stop < stops.length &&
          stopMinLongitude <= userLocation.longitude! &&
          userLocation.longitude! <= stopMaxLongitude &&
          stopMinLatitude <= userLocation.latitude! &&
          userLocation.latitude! <= stopMaxLatitude) {
        stop++;
        debugPrint('apk: Stop reached, moving to next stop: $stop');
        // Send stop reached message
        await FlutterOverlayWindow.shareData({
          'routeId': routeId,
          'nextStop': 'Stop Reached, Moving to Next Stop: $stop',
        });

        if (stop == stops.length) {
          nextStop = 'Reached';
          // Send final stop reached message
          await FlutterOverlayWindow.shareData({
            'routeId': routeId,
            'nextStop': 'Final Stop: Reached',
          });
          cancelLocationSubscription();
          return;
        }

        // Reset for next nearest stop calculation
        index = 0;
        minDistance = double.infinity;
        routeStops.removeAt(0);
      }
    });
  }

  Future<void> _dateFilter() async {
    final filtersProvider =
        Provider.of<FiltersProvider>(context, listen: false);
    DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: filtersProvider.filterDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2050));
    if (selectedDate != null) {
      filtersProvider.changeFilterDate(selectedDate);
    }
  }

  void _filterRouteByDate(
      RouteProvider routeProvider, FiltersProvider filtersProvider) {
    routeProvider.userRoutes.map((route) {
      // print(route['rrule']);
      if (route['rrule'] != null && filtersProvider.filterDate != null) {
        print('RRULE : ${route['rrule']}');
        Map<String, Object> routeSchedule = rruleParser(route['rrule']);
        if (routeSchedule['FREQ'] == 'DAILY') {
          if (routeSchedule['UNTIL'] != null &&
              (routeSchedule['UNTIL'] as DateTime)
                  .isBefore(filtersProvider.filterDate!)) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          }
        }
        if (routeSchedule['FREQ'] == 'WEEKLY') {
          if (routeSchedule['UNTIL'] != null &&
              (routeSchedule['UNTIL'] as DateTime)
                  .isBefore(filtersProvider.filterDate!) &&
              routeSchedule['BYDAY'] != null &&
              (routeSchedule['BYDAY'] as String)
                  .contains(getWeekDay(filtersProvider.filterDate!.weekday))) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else if (routeSchedule['BYDAY'] != null &&
              (routeSchedule['BYDAY'] as String)
                  .contains(getWeekDay(filtersProvider.filterDate!.weekday))) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          }
        }
        if (routeSchedule['FREQ'] == 'MONTHLY') {
          if (routeSchedule['BYMONTHDAY'] == filtersProvider.filterDate!.day) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else if (routeSchedule['BYMONTHDAY'] ==
              filtersProvider.filterDate!.day) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          }
        }
        if (routeSchedule['FREQ'] == 'YEARLY') {
          if (routeSchedule['UNTIL'] != null &&
              (routeSchedule['UNTIL'] as DateTime)
                  .isBefore(filtersProvider.filterDate!) &&
              routeSchedule['BYMONTH'] == filtersProvider.filterDate!.month &&
              routeSchedule['BYMONTHDAY'] != null &&
              routeSchedule['BYMONTHDAY'] == filtersProvider.filterDate!.day) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else if (routeSchedule['BYMONTH'] ==
                  filtersProvider.filterDate!.month &&
              routeSchedule['BYMONTHDAY'] != null &&
              routeSchedule['BYMONTHDAY'] == filtersProvider.filterDate!.day) {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else if (routeSchedule['UNTIL'] != null &&
              (routeSchedule['UNTIL'] as DateTime)
                  .isBefore(filtersProvider.filterDate!) &&
              routeSchedule['BYMONTH'] == filtersProvider.filterDate!.month &&
              routeSchedule['BYDAY'] != null &&
              (routeSchedule['BYDAY'] as String).contains(getWeekDay(filtersProvider
                  .filterDate!
                  .weekday))) // Needed to implement Fourth SUN first MON Like problems.
          {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          } else if (routeSchedule['BYMONTH'] ==
                  filtersProvider.filterDate!.month &&
              routeSchedule['BYDAY'] != null &&
              (routeSchedule['BYDAY'] as String).contains(getWeekDay(filtersProvider
                  .filterDate!
                  .weekday))) // Needed to implement Fourth SUN first MON Like problems.
          {
            List<dynamic> stops = route['stops'];
            List<LatLng> routeStops = parseGeoPoints(stops);
            filteredRouteStopsMap[route['routeName']] = routeStops;
            filteredUserRoutes.add(route);
          }
        }
      } else if (filtersProvider.filterDate == null) {
        List<dynamic> stops = route['stops'];
        List<LatLng> routeStops = parseGeoPoints(stops);
        filteredRouteStopsMap[route['routeName']] = routeStops;
        filteredUserRoutes.add(route);
      }
    }).toList();
  }

  void removeStopFromFirebase() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection('users');
      List<Map<String, dynamic>> updatedStops = [];
      Provider.of<RouteProvider>(context, listen: false).userStops.map((stop) {
        Map<String, dynamic> userAddedStop = {};
        userAddedStop['stop'] = stop['stop'];
        userAddedStop['tags'] = stop['tags'];
        userAddedStop['selectedPoint'] = osm.GeoPoint(
                latitude: (stop['selectedPoint'] as LatLng).latitude,
                longitude: (stop['selectedPoint'] as LatLng).longitude)
            .toString();
        updatedStops.add(userAddedStop);
      }).toList();
      collectionReference.doc('/${user.uid}').update({
        'useraddedstops': updatedStops,
      });
    }
  }

  void _filterRouteByStops(
      FiltersProvider filtersProvider, RouteProvider routeProvider) {
    filtersProvider.stopsIncluded?.map((e) => {routeProvider.routeStopsMap});

    int count = 0;
    for (final routeStops in routeProvider.routeStopsMap.entries) {
      for (final stop in routeStops.value) {
        for (final filteredStop in filtersProvider.stopsIncluded!) {
          double stopMinLatitude = filteredStop.latitude - 0.002;
          double stopMaxLatitude = filteredStop.latitude + 0.002;
          double stopMinLongitude = filteredStop.longitude - 0.002;
          double stopMaxLongitude = filteredStop.longitude + 0.002;
          if (stopMinLongitude <= stop.longitude &&
              stop.longitude <= stopMaxLongitude &&
              stopMinLatitude <= stop.latitude &&
              stop.latitude <= stopMaxLatitude) {
            count++;
          }
        }
      }
      if (count == filtersProvider.stopsIncluded?.length) {
        if (Provider.of<FiltersProvider>(context, listen: false).filterDate !=
            null) {
          if (filteredUserRoutes.isEmpty) {
            filteredUserRoutes = [];
            filteredRouteStopsMap = {};
          }
          filteredRouteStopsMap.entries.map((filteredRoute) {
            if (filteredRoute.key == routeStops.key) {
              filteredRouteStopsMap[routeStops.key] = routeStops.value;
              filteredUserRoutes.add({routeStops.key: routeStops.value});
            }
          });
        } else {
          filteredRouteStopsMap[routeStops.key] = routeStops.value;
          filteredUserRoutes.add({routeStops.key: routeStops.value});
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This method is called when the app state changes (resumed, paused, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned from Google Maps, cancel navigation and overlay
      // cancelNavigation();
    }
  }

  // void cancelNavigation() async {
  //   // ScaffoldMessenger.of(context).showSnackBar(
  //   //   const SnackBar(
  //   //     content: Text('Navigation Cancelled'),
  //   //   ),
  //   // );
  //   // Cancel the location stream subscription if it's active
  //   await locationStreamSubscription.cancel();
  //   // Close or hide the overlay window
  //   await FlutterOverlayWindow.closeOverlay();
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocationData>(
        stream: location.onLocationChanged,
        builder: (context, currentLocation) {
          if (currentLocation.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: AnimatedTextKit(
                  repeatForever: true,
                  isRepeatingAnimation: true,
                  animatedTexts: [
                    TyperAnimatedText('We are getting your location ...',
                        textStyle: const TextStyle(fontSize: 18)),
                    TyperAnimatedText('Please wait....',
                        textStyle: const TextStyle(fontSize: 18)),
                    TyperAnimatedText('Sorry, for the inconvenience.',
                        textStyle: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            );
          }
          _fetchCurrentLocationName(currentLocation.data!);
          marker = Marker(
            point: LatLng(currentLocation.data!.latitude!,
                currentLocation.data!.longitude!),
            child: const Icon(
              Icons.circle_sharp,
              color: Colors.blue,
              size: 16,
            ),
          );
          return Scaffold(
            drawer: showDrawer(context),
            appBar: AppBar(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              title: const Text(
                'Trip Planner',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              actions: [
                // _buildFilterButton(),
                Consumer<LoadingProvider>(
                    builder: (context, loadingProvider, child) {
                  return IconButton(
                    onPressed: () {
                      loadingProvider.changeAllRoutesScreenToggleState(
                          !loadingProvider.allRoutesScreenFilter);
                      Provider.of<FiltersProvider>(context, listen: false)
                          .stopsIncluded = [];
                      setState(() {
                        stopsFilter = false;
                      });
                      Provider.of<FiltersProvider>(context, listen: false)
                          .filterDate = null;
                    },
                    icon: const Icon(
                      Icons.search_sharp,
                      color: Colors.white,
                      size: 26,
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(
                    Icons.list_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RouteTable(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: FutureBuilder<void>(
              future: futureList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  LatLng? initialCenter;
                  return Consumer3<RouteProvider, FiltersProvider,
                          LoadingProvider>(
                      builder: (context, routeProvider, filtersProvider,
                          loadingProvider, child) {
                    filteredUserRoutes = [];
                    filteredRouteStopsMap = {};
                    bool isFiltered = true;

                    if (filtersProvider.filterDate != null) {
                      _filterRouteByDate(routeProvider, filtersProvider);
                      isFiltered = false;
                    }
                    if (filtersProvider.stopsIncluded!.isNotEmpty) {
                      _filterRouteByStops(filtersProvider, routeProvider);
                      isFiltered = false;
                    }
                    if (isFiltered) {
                      filteredUserRoutes = routeProvider.userRoutes;
                      filteredRouteStopsMap = routeProvider.routeStopsMap;
                    }
                    return Column(
                      children: [
                        loadingProvider.allRoutesScreenFilter
                            ? showsearchFilterScreen(loadingProvider, context,
                                filtersProvider, currentLocation, routeProvider)
                            : const SizedBox.shrink(),
                        showFiltersCheckList(
                            currentLocation, initialCenter, routeProvider),
                        Expanded(
                          flex: 6,
                          child: Stack(
                            children: [
                              Consumer<RouteProvider>(
                                  builder: (context, routeProvider, child) {
                                return FlutterMap(
                                  mapController: flutterMapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      currentLocation.data!.latitude!,
                                      currentLocation.data!.longitude!,
                                    ),
                                    initialZoom: 14.0,
                                  ),
                                  children: [
                                    tileLayer,
                                    for (var routeId
                                        in routeProvider.routeStopsMap.keys)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: routeProvider
                                                .routeStopsMap[routeId]!,
                                            strokeWidth:
                                                routeId == selectedRouteId
                                                    ? 5
                                                    : 3,
                                            color: routeId == selectedRouteId
                                                ? Colors.red
                                                : _getRouteColor(
                                                    routeProvider
                                                        .routeStopsMap.keys
                                                        .toList()
                                                        .indexOf(routeId),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    MarkerLayer(
                                      markers: [
                                        marker,
                                      ],
                                    ),
                                    if (routeProvider.userRoutes.isNotEmpty)
                                      for (var routeId
                                          in Provider.of<RouteProvider>(context,
                                                  listen: false)
                                              .routeStopsMap
                                              .keys)
                                        MarkerLayer(
                                          markers: routeProvider
                                              .routeStopsMap[routeId]!
                                              .asMap()
                                              .entries
                                              .map(
                                            (entry) {
                                              int index = entry.key;
                                              LatLng latLng = entry.value;
                                              return Marker(
                                                point: latLng,
                                                child: Stack(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on_sharp,
                                                    ),
                                                    Positioned(
                                                      bottom: 1,
                                                      left: 1,
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: TextStyle(
                                                          color: routeId ==
                                                                  selectedRouteId
                                                              ? Colors.red
                                                              : _getRouteColor(
                                                                  routeProvider
                                                                      .routeStopsMap
                                                                      .keys
                                                                      .toList()
                                                                      .indexOf(
                                                                        routeId,
                                                                      ),
                                                                ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ).toList(),
                                        ),
                                    if (routeProvider.userStops.isNotEmpty)
                                      MarkerLayer(
                                        markers: [
                                          marker,
                                          ...routeProvider.userStops
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key;
                                            LatLng latLng =
                                                entry.value['selectedPoint'];
                                            return Marker(
                                              point: latLng,
                                              child: Stack(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_sharp,
                                                  ),
                                                  Positioned(
                                                    bottom: 1,
                                                    left: 1,
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                  ],
                                );
                              }),
                              Positioned(
                                right: 15,
                                bottom: 15,
                                child: Consumer<LoadingProvider>(
                                  builder: (BuildContext context,
                                      LoadingProvider loadingProvider,
                                      Widget? child) {
                                    return FloatingActionButton(
                                      onPressed: () async {
                                        loadingProvider
                                            .changAllRoutesUpdateLocationState(
                                                true);
                                        // currentLocation =
                                        //     await fetchCurrentLocation();
                                        loadingProvider
                                            .changAllRoutesUpdateLocationState(
                                                false);
                                        setState(() {
                                          marker = Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(
                                                currentLocation.data!.latitude!,
                                                currentLocation
                                                    .data!.longitude!),
                                            child: const Icon(
                                              Icons.circle_sharp,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                          );
                                        });
                                        flutterMapController.move(
                                            LatLng(
                                              currentLocation.data!.latitude!,
                                              currentLocation.data!.longitude!,
                                            ),
                                            18);
                                        locationName = await getPlaceName(
                                            currentLocation.data!.latitude!,
                                            currentLocation.data!.longitude!);
                                      },
                                      child: loadingProvider
                                              .allRoutesUpdateLocation
                                          ? const Center(
                                              child: SizedBox(
                                                width: 25,
                                                height: 25,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (filteredRouteStopsMap.isEmpty &&
                            routeProvider.userStops.isEmpty)
                          const Expanded(
                            flex: 4,
                            child: Center(
                              child: Text(
                                'No routes and stops are added',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 20),
                              ),
                            ),
                          ),
                        if (filteredRouteStopsMap.isNotEmpty ||
                            routeProvider.userStops.isNotEmpty)
                          Expanded(
                            flex: 4,
                            child: ListView.builder(
                              itemCount: filteredRouteStopsMap.length +
                                  (routeProvider.userStops.length),
                              itemBuilder: (context, index) {
                                if (index < filteredRouteStopsMap.length) {
                                  var routeName = filteredRouteStopsMap.keys
                                      .toList()[index];
                                  var routePoints =
                                      filteredRouteStopsMap[routeName]!;
                                  var tags = '';
                                  for (var element in filteredUserRoutes) {
                                    if (element['routeName'] == routeName) {
                                      tags = element['tags'];
                                    }
                                  }
                                  bool isTagSelected = false;
                                  for (final tag in selectedTags) {
                                    if (tags.split(',').contains(tag) ||
                                        tag == 'All') {
                                      isTagSelected = true;
                                      break;
                                    }
                                  }
                                  if (selectedTags.isEmpty) {
                                    isTagSelected = true;
                                  }
                                  if (!isTagSelected) {
                                    return const SizedBox.shrink();
                                  }
                                  LatLng? initialPoint;
                                  return ListTile(
                                    title: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            routeName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '(tags: $tags)',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (routeProvider.routeStopsNames[
                                                    routeName] ==
                                                null ||
                                            routeProvider
                                                .routeStopsNames[routeName]!
                                                .isEmpty)
                                          const Text(
                                            'Loading...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (routeProvider
                                                .routeStopsNames[routeName] !=
                                            null)
                                          for (int stop = 0;
                                              stop <
                                                  routeProvider
                                                      .routeStopsNames[
                                                          routeName]!
                                                      .length;
                                              stop++)
                                            Text(
                                              'Point ${stop + 1} : ${routeProvider.routeStopsNames[routeName]![stop]}',
                                            ),
                                      ],
                                    ),
                                    onTap: () {
                                      initialPoint = routePoints[0];
                                      setState(() {
                                        selectedRouteId = routeName;
                                        flutterMapController.move(
                                            LatLng(initialPoint!.latitude,
                                                initialPoint!.longitude),
                                            14);
                                      });
                                    },
                                    trailing: showMenuPopUp(
                                        context, routeName, currentLocation),
                                    selected: selectedRouteId == routeName,
                                    tileColor: selectedRouteId == routeName
                                        ? Colors.grey
                                        : null,
                                  );
                                } else {
                                  // For user-added stops
                                  if (routeProvider.userStops.isNotEmpty) {
                                    var userStop = routeProvider.userStops[
                                        index - filteredUserRoutes.length];
                                    var tags = userStop['tags'].split(',');
                                    bool isTagSelected = false;
                                    for (final tag in selectedTags) {
                                      if (tags.contains(tag) || tag == 'All') {
                                        isTagSelected = true;
                                        break;
                                      }
                                    }
                                    if (selectedTags.isEmpty) {
                                      isTagSelected = true;
                                    }
                                    if (!isTagSelected) {
                                      return const SizedBox.shrink();
                                    }
                                    return ListTile(
                                      title: Text(
                                        userStop['stop'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Tags: ${userStop['tags']}',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          flutterMapController.move(
                                              routeProvider.userStops[index -
                                                      filteredUserRoutes.length]
                                                  ['point'],
                                              14);
                                          centeredRouteId = null;
                                        });
                                      },
                                      trailing: PopupMenuButton(
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            PopupMenuItem(
                                              onTap: () async {
                                                List<String> stopTags =
                                                    (userStop['tags'] as String)
                                                        .split(',');
                                                await Navigator.of(context)
                                                    .push(
                                                  MaterialPageRoute(
                                                    builder: (ctx) =>
                                                        AddStopScreen(
                                                      filteredTags: stopTags,
                                                      allTags: allTagsList,
                                                      currentLocationData:
                                                          LocationData.fromMap({
                                                        'latitude': userStop[
                                                                'selectedPoint']
                                                            .latitude,
                                                        'longitude': userStop[
                                                                'selectedPoint']
                                                            .longitude,
                                                      }),
                                                      locationName:
                                                          userStop['stop'],
                                                      isEdit: true,
                                                      index: index -
                                                          filteredUserRoutes
                                                              .length,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              onTap: () {
                                                routeProvider.deleteStop(index -
                                                    filteredUserRoutes.length);
                                                removeStopFromFirebase();
                                              },
                                              child: const Text('Delete'),
                                            ),
                                            PopupMenuItem(
                                              onTap: () {
                                                List<LatLng> stops = [
                                                  LatLng(
                                                      currentLocation
                                                          .data!.latitude!,
                                                      currentLocation
                                                          .data!.longitude!),
                                                  userStop['selectedPoint']
                                                ];
                                                _startNavigation(stops);
                                              },
                                              child: const Text('Navigate'),
                                            ),
                                          ];
                                        },
                                      ),
                                    );
                                  } else {
                                    return const ListTile(
                                      title:
                                          Text('No user-added stops available'),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    );
                  });
                }
              },
            ),
            floatingActionButton: hasSkippedLogin
                ? null // Hide the button if user has skipped login
                : FloatingActionButtonCustom(
              selectedTags: selectedTags,
              locationName: locationName,
              allTagsList: allTagsList,
              cl: currentLocation,
            ),
          );
        });
  }

  Drawer showDrawer(BuildContext context) {
    return Drawer(
      surfaceTintColor: Colors.green,
      width: 250,
      backgroundColor: Colors.green.shade200,
      shadowColor: Colors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            color: Colors.green,
            child: const Center(
              child: FlutterLogo(
                size: 45,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Consumer<UserInfoProvider>(
              builder: (context, userInfoProvider, child) {
            return Text('Name: ${userInfoProvider.userName}');
          }),
          const SizedBox(height: 10),
          Consumer<UserInfoProvider>(
              builder: (context, userInfoProvider, child) {
            return Text('Date of Birth: ${userInfoProvider.dateOfBirth}');
          }),
          const SizedBox(height: 10),
          Consumer<UserInfoProvider>(
              builder: (context, userInfoProvider, child) {
            return Text('Phone Number: ${userInfoProvider.phoneNumber}');
          }),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _importRoute,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Route'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              await _clearPreferences();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  PopupMenuButton<String> showMenuPopUp(BuildContext context, String routeName,
      AsyncSnapshot<LocationData> currentLocation) {
    return PopupMenuButton<String>(
      elevation: 8,
      onSelected: (String value) async {
        if (value == 'edit') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteEditScreen(
                routeName: routeName,
                currentLocationData: currentLocation.data!,
                allTags: allTagsList,
              ),
            ),
          );
        } else if (value == 'duplicate') {
          // Implement copy functionality

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteCopyScreen(
                routeName: routeName,
              ),
            ),
          );
        } else if (value == 'delete') {
          // print('Oops!, lets delete this.');
          // Implement delete functionality
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text(
                    'Your route $routeName will be deleted. Do you want to continue?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Provider.of<RouteProvider>(
                        context,
                        listen: false,
                      ).deleteRoute(routeName);
                      _deleteRoute(routeName: routeName);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        } else if (value == 'navigate') {
          // print('lets navigate! ohoo');
        } else if (value == 'share') {
          // print('lets share it');
          encodeAndShareRoute(routeName);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('duplicate'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete'),
          ),
        ),
        PopupMenuItem(
          value: 'navigate',
          child: ListTile(
            leading: const Icon(Icons.navigation_rounded),
            title: const Text('Navigate'),
            onTap: () async {
              List<LatLng> stops = filteredRouteStopsMap[routeName]!;
              _startNavigation(stops);
              locationStreamSubscription =
                  location.onLocationChanged.listen((event) {});
              nextStop = 'Getting Location ...';
              stop = 0;
              FlutterOverlayWindow.showOverlay(
                height: 400, // 350
                width: 900,
                enableDrag: true,
                overlayTitle: routeName,
              );
              await FlutterOverlayWindow.shareData({
                'routeId': null,
                'nextStop': nextStop,
              });
              await getNextStop(stops, routeName);
            },
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('Share'),
          ),
        ),
      ],
    );
  }

  SizedBox showFiltersCheckList(AsyncSnapshot<LocationData> currentLocation,
      LatLng? initialCenter, RouteProvider routeProvider) {
    return SizedBox(
      height: 25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allTagsList.length,
        itemBuilder: (ctx, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected[index],
                onChanged: (isChecked) {
                  if (isChecked!) {
                    if (allTagsList[index] == 'All') {
                      setState(() {
                        selectedTags = ['All'];
                      });
                    } else {
                      selectedTags.add(allTagsList[index]);
                    }
                    setState(() {
                      isSelected[index] = isChecked;
                    });
                  } else {
                    setState(() {
                      isSelected[index] = isChecked;
                      selectedTags.remove(allTagsList[index]);
                    });
                  }
                  int count = 0;
                  List<LatLng?> initialCenterList =
                      filteredRouteStopsMap.isEmpty
                          ? []
                          : selectedTags.isEmpty
                              ? [
                                  LatLng(currentLocation.data!.latitude!,
                                      currentLocation.data!.longitude!)
                                ]
                              : filteredRouteStopsMap.entries.map((e) {
                                  if (e.key.trim() == selectedTags[0].trim()) {
                                    if (count == 0) {
                                      return filteredRouteStopsMap[e.key]?[0];
                                    }
                                    count++;
                                  }
                                }).toList();
                  count = 0;
                  if (initialCenterList[0] != null) {
                    initialCenter = initialCenterList[0];
                    setState(() {
                      flutterMapController.move(initialCenterList[0]!, 14);
                    });
                  } else {
                    if (routeProvider.userStops.isNotEmpty) {
                      routeProvider.userStops.map((value) {
                        if (value['tags'].toString().trim() ==
                            selectedTags[0].trim()) {
                          if (count == 0) {
                            value.entries.map((e) async {
                              initialCenter = value['point'];
                              setState(() {
                                flutterMapController.move(initialCenter!, 14);
                              });
                            }).toList();
                          }
                          count++;
                        }
                        count = 0;
                      }).toList();
                    }
                  }
                },
              ),
              Text(allTagsList[index]),
            ],
          );
        },
      ),
    );
  }

  SizedBox showsearchFilterScreen(
      LoadingProvider loadingProvider,
      BuildContext context,
      FiltersProvider filtersProvider,
      AsyncSnapshot<LocationData> currentLocation,
      RouteProvider routeProvider) {
    return SizedBox(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FilterItem(
                label: 'By Date',
                onTapped: _dateFilter,
              ),
              const FilterItem(label: 'By Time', onTapped: null),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    loadingProvider.changeAllRoutesScreenToggleState(
                        !loadingProvider.allRoutesScreenFilter);
                    Provider.of<FiltersProvider>(context, listen: false)
                        .stopsIncluded = [];
                    setState(() {
                      stopsFilter = false;
                    });
                    Provider.of<FiltersProvider>(context, listen: false)
                        .filterDate = null;
                  },
                  icon: const Icon(
                    Icons.cancel,
                  )),
            ],
          ),
          Expanded(
            child: FutureBuilder(
                future: _stopsFilter(filtersProvider.stopsIncluded),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TyperAnimatedText('Getting location name....'),
                        ],
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    itemCount: filtersProvider.stopsIncluded!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        key: ValueKey(index),
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          left: 10,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              children: [
                                const Icon(Icons.reorder),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    controller: filterStopsController[index],
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.gps_not_fixed),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                IconButton(
                                  onPressed: () {
                                    filtersProvider.excludeStop(index);
                                  },
                                  icon: const Icon(Icons.remove_circle),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex--;
                      }
                      filtersProvider.stopsIncluded!.insert(newIndex,
                          filtersProvider.stopsIncluded!.removeAt(oldIndex));
                    },
                  );
                }),
          ),
          ElevatedButton(
            onPressed: () async {
              List<dynamic> selectedStop = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => RouteAddStopScreen(
                    currentLocationData: currentLocation.data!,
                    displayedUserAddedStops: routeProvider.userStops,
                  ),
                ),
              );
              filtersProvider.includedStops(selectedStop[1] as osm.GeoPoint);
            },
            child: const Text('search by stop'),
          ),
        ],
      ),
    );
  }
}

class FloatingActionButtonCustom extends StatelessWidget {
  const FloatingActionButtonCustom({
    super.key,
    required this.selectedTags,
    required this.locationName,
    required this.allTagsList,
    required this.cl,
  });

  final List<String> selectedTags;
  final String? locationName;
  final List<String> allTagsList;
  final AsyncSnapshot<LocationData> cl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Consumer<LoadingProvider>(
          builder: (BuildContext context, value, Widget? child) {
            return FloatingActionButton(
              heroTag: null,
              mini: true,
              backgroundColor: Colors.green,
              onPressed: value.locationLoading
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Getting your location',
                          ),
                          action: SnackBarAction(
                              label: 'Ok',
                              onPressed:
                                  ScaffoldMessenger.of(context).clearSnackBars),
                        ),
                      );
                    }
                  : () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteCreationScreen(
                            selectedTags: selectedTags,
                            locationName: locationName,
                            currentLocationData: cl.data!,
                            allTags: allTagsList,
                          ),
                        ),
                      );
                    },
              child: value.locationLoading
                  ? const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.add_road_sharp,
                      color: Colors.white,
                    ),
            );
          },
        ),
        const SizedBox(width: 16),
        Consumer<LoadingProvider>(
          builder:
              (BuildContext context, LoadingProvider value, Widget? child) {
            return FloatingActionButton(
              heroTag: null,
              mini: true,
              onPressed: value.locationLoading
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Getting your location',
                          ),
                          action: SnackBarAction(
                            label: 'Ok',
                            onPressed:
                                ScaffoldMessenger.of(context).clearSnackBars,
                          ),
                        ),
                      );
                    }
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddStopScreen(
                            filteredTags: selectedTags,
                            allTags: allTagsList,
                            currentLocationData: cl.data!,
                            locationName: locationName,
                          ),
                        ),
                      );
                    },
              backgroundColor: Colors.green,
              child: value.locationLoading
                  ? const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.add_location_alt_outlined,
                      color: Colors.white,
                    ),
            );
          },
        )
      ],
    );
  }
}

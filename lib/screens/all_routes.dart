// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:driver_app/providers/loading_provider.dart';
import 'package:driver_app/screens/add_stop.dart';
import 'package:driver_app/screens/login.dart';
import 'package:driver_app/screens/route_creation_screen.dart';
import 'package:driver_app/screens/route_edit_screen.dart';
import 'package:driver_app/screens/route_copy_screen.dart';
import 'package:driver_app/widgets/route_table.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

Future<String?> getPlaceName(double latitude, double longitude) async {
  do {
    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
      ),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['display_name'];
    }
  } while (true);
}

Future<LocationData?> fetchCurrentLocation() async {
  Location location = Location();

  bool servicesEnabled = await location.serviceEnabled();
  if (!servicesEnabled) {
    servicesEnabled = await location.requestService();
    if (!servicesEnabled) {
      return null;
    }
  }

  PermissionStatus permissionStatus = await location.hasPermission();
  if (permissionStatus != PermissionStatus.granted) {
    permissionStatus = await location.requestPermission();
    if (permissionStatus != PermissionStatus.granted) {
      return null;
    }
  }
  try {
    LocationData userLocation = await location.getLocation();
    return userLocation;
  } catch (e) {
    print('Error fetching location: $e');
  }
}

class AllRoutesMapScreen extends StatefulWidget {
  const AllRoutesMapScreen({super.key});

  @override
  State<AllRoutesMapScreen> createState() => _AllRoutesMapScreenState();
}

class _AllRoutesMapScreenState extends State<AllRoutesMapScreen> {
  late MapController flutterMapController;
  Map<String, List<LatLng>> routeStopsMap = {};
  LocationData? currentLocation;
  String? selectedRouteId;
  String? centeredRouteId;

  // List<dynamic> filteredRoutes = [];
  // List<dynamic> filteredStops = [];
  String? selectedTag;

  List<Map<String, dynamic>> userAddedStops = [];
  List<dynamic> userRoutes1 = [];
  List<dynamic> displayedRoutes = [];

  String userName = '';
  String dateOfBirth = '';
  String phoneNumber = '';
  List<String> allTagsList = ['All'];
  int previousIndex = 0;
  List<bool> isSelected = [];
  Future<List<String>>? futureList;
  String? locationName;
  Future<bool>? getLocation;
  String nextStop = 'Getting your location...';
  late StreamSubscription userCurrentLocation;

  // bool isReached = false;
  Location location = Location();
  int stop = 0;
  late StreamSubscription<LocationData> locationStreamSubscription;
  late Marker marker;

  @override
  void initState() {
    super.initState();
    flutterMapController = MapController();
    getLocation = _fetchCurrentLocationName();
    isSelected.add(true);
    futureList = _fetchAllStops();
  }

  Future<bool> _fetchCurrentLocationName() async {
    // Provider.of<LoadingProvider>(context, listen: false)
    //     .changeLocationLoadingState(true);
    currentLocation = await fetchCurrentLocation() ??
        LocationData.fromMap({'latitude': 37.4219983, 'longitude': -122.084});
    locationName = await getPlaceName(
        currentLocation!.latitude!, currentLocation!.longitude!);
    Provider.of<LoadingProvider>(context, listen: false)
        .changeLocationLoadingState(false);
    return true;
  }

  List<LatLng> _parseGeoPoints(List<dynamic> geoPoints) {
    return geoPoints.map((geoPointString) {
      RegExp regex = RegExp(r'([0-9]+\.[0-9]+)');
      Iterable<Match> matches = regex.allMatches(geoPointString);

      double latitude = double.parse(matches.elementAt(0).group(0)!);
      double longitude = double.parse(matches.elementAt(1).group(0)!);

      return LatLng(
        latitude,
        longitude,
      );
    }).toList();
  }

  Future<List<String>> _fetchAllStops() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      userName = userDoc.get('name');
      dateOfBirth = userDoc.get('dateofbirth');
      phoneNumber = userDoc.get('phoneNumber');
      print('userDoc.get(routes) - ${userDoc.get('routes')}');
      List<dynamic> userRoutes = userDoc.get('routes') ?? [];
      userRoutes1 = userRoutes;
      userRoutes.forEach((route) {
        List<dynamic> stops = route['stops'];
        List<LatLng> routeStops = _parseGeoPoints(stops);
        routeStopsMap[route['routeName']] = routeStops;
      });
      List<dynamic> userAddedStopsData = [];
      if (userDoc.get('useraddedstops').runtimeType != String) {
        userAddedStopsData = userDoc.get('useraddedstops');
      }
      userAddedStops = userAddedStopsData.map((stopData) {
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
            'point': LatLng(latitude, longitude),
          };
        }
        return <String, String>{};
      }).toList();

      // Get all tags from routes and user-added stops
      Set<String> allTags = <String>{};
      allTags.add('All');
      for (var route in userRoutes1) {
        List<String> tags = route['tags'].split(',');
        allTags.addAll(tags);
      }

      userAddedStops.removeWhere((element) => element.isEmpty);

      for (var stop in userAddedStops) {
        allTags.addAll(stop['tags'].split(','));
      }

      allTagsList = allTags.toList();
      allTagsList.removeWhere((element) => element.isEmpty);

      for (int i = 1; i < allTagsList.length; i++) {
        isSelected.add(false);
      }
    }

    return allTagsList;
  }

  Color _getRouteColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  // Future<void> _showFilterDialog() async {
  //   String? result = await showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Select Tag to Filter'),
  //         content: DropdownButton<String>(
  //           hint: const Text('select tags to filter the routes!'),
  //           icon: const Icon(Icons.filter_alt),
  //           value: selectedTag,
  //           items: allTagsList.map((tag) {
  //             return DropdownMenuItem<String>(
  //               value: tag,
  //               child: Text(tag),
  //             );
  //           }).toList(),
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               selectedTag = newValue;
  //               _applyFilter();
  //             });
  //             Navigator.of(context).pop(newValue!);
  //           },
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               setState(() {
  //                 selectedTag = null;
  //                 _applyFilter();
  //               });
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Clear Filter'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //   print(result);
  // }

  // void _applyFilter() {
  //   setState(() {
  //     if (selectedTag != null) {
  //       filteredRoutes = userRoutes1.where((route) {
  //         String tagsString = route['tags'];
  //         List<String> tags = tagsString.split(',');
  //         return tags.contains(selectedTag);
  //       }).toList();
  //
  //       filteredStops = userAddedStops.where((stop) {
  //         String tagsString = stop['tags'];
  //         List<String> tags = tagsString.split(',');
  //         return tags.contains(selectedTag);
  //       }).toList();
  //     } else {
  //       filteredRoutes.clear();
  //       filteredStops.clear();
  //     }
  //   });
  // }

  // Widget _buildFilterButton() {
  //   return ElevatedButton.icon(
  //     icon: const Icon(
  //       Icons.filter_alt,
  //       color: Colors.white,
  //     ),
  //     onPressed: () {
  //       _showFilterDialog();
  //     },
  //     label: Text(selectedTag != null ? 'Filter: $selectedTag' : 'Filter'),
  //     style: const ButtonStyle(
  //         backgroundColor: MaterialStatePropertyAll(Colors.amberAccent)),
  //   );
  // }

  void _deleteRoute({required String routeName}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String userID = user.uid;
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userID);

        // Fetch the current routes
        DocumentSnapshot userSnapshot = await userRef.get();
        List<dynamic> routes = userSnapshot['routes'];

        // Find the index of the route with the given routeName
        int indexToRemove =
            routes.indexWhere((route) => route['routeName'] == routeName);

        if (indexToRemove >= 0) {
          // Remove the route at indexToRemove
          routes.removeAt(indexToRemove);

          // Update the user document with the updated routes
          await userRef.update({'routes': routes});
        }

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Route deleted!'),
              content: const Text('Route removed successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
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
        print('User is not authenticated.');
      }
    } catch (e) {
      print('Error deleting route: $e');

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
    print('$baseUrl$stopsString/');
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
      print('Error uploading file: $e');
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
      print('Error getting download URL: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchRouteDetails(String routeName) async {
    User? user = FirebaseAuth.instance.currentUser;
    String userID = user!.uid;
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userID);
    // Fetch the current route
    DocumentSnapshot userSnapshot = await userRef.get();
    List<dynamic> routes = userSnapshot['routes'];
    int indexToFetch =
        routes.indexWhere((route) => route['routeName'] == routeName);
    if (indexToFetch >= 0) {
      Map<String, dynamic> route = routes[indexToFetch];
      print('route: $route');
      return route;
    }
    return {};
  }

  Future<void> encodeAndShareRoute(String routeName) async {
    Map<String, dynamic> routeDetails = await fetchRouteDetails(routeName);
    String jsonData = jsonEncode(routeDetails);
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$routeName.json');
    await file.writeAsString(jsonData);

    await uploadFileToFirebaseStorage(file, routeName);

    String? downloadUrl = await getFirebaseStorageDownloadUrl(routeName);

    if (downloadUrl != null) {
      Share.share('Check out this route: $downloadUrl');
    } else {
      print('Error: Could not get download URL');
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
                Navigator.of(context).pop(urlController.text);
              },
              child: const Text('Import'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
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

          // Add the route data to Firestore
          await _addRouteToFirestore(routeData);

          // Show success dialog
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
        } else {
          throw Exception('Error downloading route data');
        }
      } catch (e) {
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

  Future<void> _addRouteToFirestore(Map<String, dynamic> routeData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userID = user.uid;
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userID);

      // Fetch the current routes
      DocumentSnapshot userSnapshot = await userRef.get();
      List<dynamic> routes = userSnapshot['routes'];

      // Check if the route already exists
      if (routes.any((route) => route['routeName'] == routeData['routeName'])) {
        throw Exception('Route with the same name already exists');
      }

      // Add the new route to the routes list
      routes.add(routeData);

      // Update the user document with the updated routes
      await userRef.update({'routes': routes});
    }
  }

  // Stream<LatLng> getUserCurrentLocation() async* {
  //   LocationData previousLocationData;
  //   LocationData locationData =
  //       LocationData.fromMap({'latitude': 37.4219983, 'longitude': -122.084});
  //   do {
  //     previousLocationData = locationData;
  //     locationData = await location.getLocation();
  //     if (locationData.latitude == previousLocationData.latitude &&
  //         locationData.longitude == previousLocationData.longitude) {
  //       continue;
  //     }
  //     yield LatLng(locationData.latitude!, locationData.longitude!);
  //   } while (!isReached);
  // }

  void cancelLocationSubscription() {
    locationStreamSubscription.cancel();
  }

  Future<void> getNextStop(List<LatLng> stops) async {
    List<LatLng> routeStops = [...stops];
    location.enableBackgroundMode(enable: true);

    locationStreamSubscription.onData((userLocation) async {
      print('TIMER : ${DateTime.now().second}');
      double latDifference = 100;
      // double lngDifference = 100;
      int index = 0;
      for (int i = 0; i < routeStops.length; i++) {
        double difference =
            (userLocation.latitude! - routeStops[i].latitude).abs();
        if (difference < latDifference) {
          index = i;
          latDifference = difference;
        }
      }
      LatLng nearestStop = routeStops[index];
      routeStops.removeAt(index);
      routeStops.insert(0, nearestStop);

      if (routeStops.isNotEmpty) {
        String? locationName =
            await getPlaceName(routeStops[0].latitude, routeStops[0].longitude);
        if(nextStop != locationName)
          {
            nextStop = locationName!;
            await FlutterOverlayWindow.shareData(locationName);
          }
      }
      double stopMinLatitude = routeStops[0].latitude - 0.002;
      double stopMaxLatitude = routeStops[0].latitude + 0.002;
      double stopMinLongitude = routeStops[0].longitude - 0.002;
      double stopMaxLongitude = routeStops[0].longitude + 0.002;
      if (stop < stops.length &&
          stopMinLongitude <= userLocation.longitude! &&
          userLocation.longitude! <= stopMaxLongitude &&
          stopMinLatitude <= userLocation.latitude! &&
          userLocation.latitude! <= stopMaxLatitude) {
        print(
            'LOCATION REACHED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        stop++;
        if (stop == stops.length) {
          nextStop = 'Reached';
          await FlutterOverlayWindow.shareData(nextStop);
          cancelLocationSubscription();
          return;
        }
        index = 0;
        latDifference = 100;
        routeStops.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        surfaceTintColor: Colors.amber,
        width: 250,
        backgroundColor: Colors.amber.shade200,
        shadowColor: Colors.cyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              color: Colors.amber,
              child: const Center(
                child: FlutterLogo(
                  size: 45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Name: $userName'),
            const SizedBox(height: 10),
            Text('Date of Birth: $dateOfBirth'),
            const SizedBox(height: 10),
            Expanded(child: Text('Phone Number: $phoneNumber')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _importRoute,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Route'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                await _clearPreferences();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Driver App',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          // _buildFilterButton(),
          IconButton(
            icon: const Icon(
              Icons.list_outlined,
              color: Colors.white,
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
        backgroundColor: Colors.amber,
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
            return Column(
              children: [
                SizedBox(
                  height: 25,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: allTagsList.length,
                          itemBuilder: (ctx, index) {
                            return InkWell(
                              onTap: () {
                                if (previousIndex != index) {
                                  isSelected[previousIndex] = false;
                                  isSelected[index] = true;
                                  previousIndex = index;
                                  if (allTagsList[index] == 'All') {
                                    setState(() {
                                      selectedTag = null;
                                    });
                                  } else {
                                    setState(() {
                                      selectedTag = allTagsList[index];
                                    });
                                    int count = 0;
                                    List<LatLng?> initialCenterList =
                                        routeStopsMap.isEmpty
                                            ? []
                                            : routeStopsMap.entries.map((e) {
                                                if (e.key.trim() ==
                                                    selectedTag?.trim()) {
                                                  if (count == 0) {
                                                    return routeStopsMap[e.key]
                                                        ?[0];
                                                  }
                                                  count++;
                                                }
                                              }).toList();
                                    count = 0;
                                    if (initialCenterList[0] != null) {
                                      initialCenter = initialCenterList[0];
                                      setState(() {
                                        flutterMapController.move(
                                            initialCenterList[0]!, 14);
                                      });
                                    } else {
                                      if (userAddedStops.isNotEmpty) {
                                        userAddedStops.map((value) {
                                          if (value['tags'].toString().trim() ==
                                              selectedTag?.trim()) {
                                            if (count == 0) {
                                              print(
                                                  'value[tags].toString().trim() == selectedTag?.trim() ${value['tags'].toString().trim()}'
                                                  '${selectedTag?.trim()}');
                                              value.entries.map((e) async {
                                                initialCenter = value['point'];
                                                print(await getPlaceName(
                                                    initialCenter!.latitude,
                                                    initialCenter!.longitude));
                                                print(
                                                    "INITIAL CENTER ==> $initialCenter");
                                                setState(() {
                                                  flutterMapController.move(
                                                      initialCenter!, 14);
                                                });
                                              }).toList();
                                            }
                                            count++;
                                          }
                                          count = 0;
                                        }).toList();
                                      }
                                    }
                                  }
                                }
                                // _applyFilter();
                              },
                              child: Container(
                                decoration: isSelected[index]
                                    ? const BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Colors.grey, width: 4)))
                                    : null,
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      allTagsList[index],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: FutureBuilder(
                    future: getLocation,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: AnimatedTextKit(
                            repeatForever: true,
                            isRepeatingAnimation: true,
                            animatedTexts: [
                              TyperAnimatedText(
                                  'We are getting your location ...',
                                  textStyle: const TextStyle(fontSize: 18)),
                              TyperAnimatedText('Please wait....',
                                  textStyle: const TextStyle(fontSize: 18)),
                              TyperAnimatedText('Sorry, for the inconvenience.',
                                  textStyle: const TextStyle(fontSize: 18)),
                            ],
                          ),
                        );
                      }
                      marker = Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(currentLocation!.latitude!,
                            currentLocation!.longitude!),
                        child: const Icon(
                          Icons.circle_sharp,
                          color: Colors.blue,
                          size: 16,
                        ),
                      );
                      return Stack(
                        children: [
                          FlutterMap(
                            mapController: flutterMapController,
                            options: MapOptions(
                              initialCenter: currentLocation != null
                                  ? LatLng(
                                      currentLocation!.latitude!,
                                      currentLocation!.longitude!,
                                    )
                                  : const LatLng(
                                      9.75527985137314, 76.64998268216185),
                              initialZoom: 14.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              ),
                              for (var routeId in routeStopsMap.keys)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routeStopsMap[routeId]!,
                                      strokeWidth:
                                          routeId == selectedRouteId ? 6 : 4,
                                      color: routeId == selectedRouteId
                                          ? Colors.red
                                          : _getRouteColor(
                                              routeStopsMap.keys
                                                  .toList()
                                                  .indexOf(routeId),
                                            ),
                                    ),
                                  ],
                                ),
                              if (userRoutes1.isEmpty)
                                MarkerLayer(
                                  markers: [
                                    marker,
                                  ],
                                ),
                              if (userRoutes1.isNotEmpty)
                                for (var routeId in routeStopsMap.keys)
                                  MarkerLayer(
                                    markers: routeStopsMap[routeId]!
                                        .asMap()
                                        .entries
                                        .map(
                                      (entry) {
                                        int index = entry.key;
                                        LatLng latLng = entry.value;
                                        return Marker(
                                          width: 80.0,
                                          height: 80.0,
                                          point: latLng,
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: 27.4,
                                                left: 25,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    color: routeId ==
                                                            selectedRouteId
                                                        ? Colors.red
                                                        : _getRouteColor(
                                                            routeStopsMap.keys
                                                                .toList()
                                                                .indexOf(
                                                                    routeId)),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                              if (userAddedStops.isNotEmpty)
                                MarkerLayer(
                                  markers: [
                                    marker,
                                    ...userAddedStops
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      int index = entry.key;
                                      LatLng latLng = entry.value['point'];
                                      return Marker(
                                        width: 80.0,
                                        height: 80.0,
                                        point: latLng,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 27.4,
                                              left: 25,
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                )
                            ],
                          ),
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
                                    currentLocation =
                                        await fetchCurrentLocation();
                                    loadingProvider
                                        .changAllRoutesUpdateLocationState(
                                            false);
                                    print(
                                        'Updated Location  ==>  $currentLocation');
                                    setState(() {
                                      marker = Marker(
                                        width: 80.0,
                                        height: 80.0,
                                        point: LatLng(
                                            currentLocation!.latitude!,
                                            currentLocation!.longitude!),
                                        child: const Icon(
                                          Icons.circle_sharp,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                      );
                                    });
                                    flutterMapController.move(
                                        LatLng(
                                          currentLocation!.latitude!,
                                          currentLocation!.longitude!,
                                        ),
                                        14);
                                    locationName = await getPlaceName(
                                        currentLocation!.latitude!,
                                        currentLocation!.longitude!);
                                  },
                                  child: loadingProvider.allRoutesUpdateLocation
                                      ? const Center(
                                          child: SizedBox(
                                            width: 25,
                                            height: 25,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.location_searching,
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (routeStopsMap.isEmpty && userAddedStops.isEmpty)
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
                if (routeStopsMap.isNotEmpty || userAddedStops.isNotEmpty)
                  Expanded(
                    flex: 4,
                    child: ListView.builder(
                      itemCount: routeStopsMap.length + (userAddedStops.length),
                      itemBuilder: (context, index) {
                        if (index < routeStopsMap.length) {
                          var routeName = routeStopsMap.keys.toList()[index];
                          var routePoints = routeStopsMap[routeName]!;
                          var tags = '';
                          for (var element in userRoutes1) {
                            if (element['routeName'] == routeName) {
                              tags = element['tags'];
                            }
                          }
                          if (selectedTag != null &&
                              !tags.split(',').contains(selectedTag)) {
                            return const SizedBox.shrink();
                          }
                          LatLng? initialPoint;
                          return ListTile(
                            title: Row(
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  routePoints.asMap().entries.map((entry) {
                                int pointIndex = entry.key + 1;
                                LatLng point = entry.value;
                                if (entry.key == 0) {
                                  initialPoint = entry.value;
                                }
                                return FutureBuilder(
                                    future: getPlaceName(
                                        point.latitude, point.longitude),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text('Loading..');
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        String? placeName = snapshot.data;
                                        return Text(
                                            'Point $pointIndex: $placeName');
                                      }
                                    });
                              }).toList(),
                            ),
                            onTap: () {
                              setState(() {
                                flutterMapController.move(
                                    LatLng(initialPoint!.latitude,
                                        initialPoint!.longitude),
                                    14);
                              });
                            },
                            trailing: PopupMenuButton<String>(
                              elevation: 8,
                              onSelected: (String value) {
                                if (value == 'edit') {
                                  print('Lets Edit this');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouteEditScreen(
                                        routeName: routeName,
                                        currentLocationData: currentLocation,
                                      ),
                                    ),
                                  );
                                  // Implement edit functionality
                                } else if (value == 'duplicate') {
                                  // Implement copy functionality
                                  print('lets copy this');
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => RouteCopyScreen(
                                              routeName: routeName)));
                                } else if (value == 'delete') {
                                  print('Oops!, lets delete this.');
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
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _deleteRoute(
                                                  routeName: routeName);
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else if (value == 'navigate') {
                                  print('lets navigate! ohoo');
                                } else if (value == 'share') {
                                  print('lets share it');
                                  encodeAndShareRoute(routeName);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
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
                                    leading:
                                        const Icon(Icons.navigation_rounded),
                                    title: const Text('Navigate'),
                                    onTap: () async {
                                      List<LatLng> stops =
                                          routeStopsMap[routeName]!;
                                      print('stops $stops');
                                      _startNavigation(stops);
                                      locationStreamSubscription = location.onLocationChanged.listen((event) {});
                                      nextStop = 'Getting Location ...';
                                      stop = 0;
                                      FlutterOverlayWindow.showOverlay(
                                          height: 350, // 350
                                          width: 900,
                                          enableDrag: true);
                                      await FlutterOverlayWindow.shareData(
                                          'Getting Location ...');
                                      await getNextStop(stops);
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
                            ),
                            selected: selectedRouteId == routeName,
                            tileColor: selectedRouteId == routeName
                                ? Colors.grey
                                : null,
                          );
                        } else {
                          // For user-added stops
                          if (userAddedStops.isNotEmpty) {
                            var userStop =
                                userAddedStops[index - routeStopsMap.length];
                            // print(userStop['tags']);
                            var tags = userStop['tags'].split(',');
                            if (selectedTag != null &&
                                !tags.contains(selectedTag)) {
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
                                      userAddedStops[index -
                                          routeStopsMap.length]['point'],
                                      14);
                                  centeredRouteId = null;
                                });
                              },
                              trailing: const Text('added stops'),
                              // trailing: PopupMenuButton<String>(
                              //   elevation: 8,
                              //   onSelected: (String value) {
                              //     if (value == 'edit') {
                              //       print('Lets Edit this');
                              //       // Implement edit functionality
                              //     } else if (value == 'copy') {
                              //       // Implement copy functionality
                              //       print('lets copy this');
                              //     } else if (value == 'delete') {
                              //       print('Oops!, lets delete this.');
                              //       // Implement delete functionality
                              //     }
                              //   },
                              //   itemBuilder: (BuildContext context) =>
                              //       <PopupMenuEntry<String>>[
                              //     const PopupMenuItem<String>(
                              //       value: 'edit',
                              //       child: ListTile(
                              //         leading: Icon(Icons.edit),
                              //         title: Text('Edit'),
                              //       ),
                              //     ),
                              //     const PopupMenuItem<String>(
                              //       value: 'copy',
                              //       child: ListTile(
                              //         leading: Icon(Icons.copy),
                              //         title: Text('Copy'),
                              //       ),
                              //     ),
                              //     const PopupMenuItem<String>(
                              //       value: 'delete',
                              //       child: ListTile(
                              //         leading: Icon(Icons.delete),
                              //         title: Text('Delete'),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            );
                          } else {
                            return const ListTile(
                              title: Text('No user-added stops available'),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            );
          }
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Consumer<LoadingProvider>(
            builder: (BuildContext context, value, Widget? child) {
              return FloatingActionButton(
                heroTag: null,
                backgroundColor: Colors.amber,
                onPressed: value.locationLoading
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Getting your location',
                            ),
                            action: SnackBarAction(
                                label: 'Ok',
                                onPressed: ScaffoldMessenger.of(context)
                                    .clearSnackBars),
                          ),
                        );
                      }
                    : () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteCreationScreen(
                              selectedTag: selectedTag,
                              locationName: locationName,
                              currentLocationData: currentLocation,
                              allTags: allTagsList,
                            ),
                          ),
                        );
                      },
                child: value.locationLoading
                    ? const Center(
                        child: SizedBox(
                          width: 25,
                          height: 25,
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
                onPressed: value.locationLoading
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Getting your location',
                            ),
                            action: SnackBarAction(
                                label: 'Ok',
                                onPressed: ScaffoldMessenger.of(context)
                                    .clearSnackBars),
                          ),
                        );
                      }
                    : () async {
                        print(locationName);
                        print("Button Pressed");
                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddStopScreen(
                              filteredTag: selectedTag,
                              allTags: allTagsList,
                              currentLocationData: currentLocation,
                              locationName: locationName,
                            ),
                          ),
                        );
                        if (result != null && result) {
                          setState(() {
                            print('rendered');
                            futureList = _fetchAllStops();
                          });
                        }
                      },
                backgroundColor: Colors.amber,
                child: value.locationLoading
                    ? const Center(
                        child: SizedBox(
                          width: 25,
                          height: 25,
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
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_animations/flutter_map_animations.dart';
// import 'package:flutter_map_trip_planner/utilities/env.dart';
// import 'package:flutter_map_trip_planner/utilities/location_functions.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher_string.dart';

// class RouteDetailsScreen extends StatefulWidget {
//   final Map<String, dynamic> route;

//   const RouteDetailsScreen({super.key, required this.route});

//   @override
//   State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
// }

// class _RouteDetailsScreenState extends State<RouteDetailsScreen>
//     with TickerProviderStateMixin {
//   List<LatLng> stops = [];
//   List<LatLng> routePoints = [];
//   bool isLoading = true;
//   late AnimatedMapController animatedMapController;
//   Map<int, String> placeNames = {};

//   LatLng? userLocation;
//   @override
//   void initState() {
//     super.initState();
//     animatedMapController = AnimatedMapController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     stops = _parseGeoPoints(widget.route['stops']);
//     _fetchpathUsingGraphhopper();
//     _getUserLocation();
//   }

//   List<LatLng> _parseGeoPoints(List<dynamic> geoPoints) {
//     return geoPoints.map((geoPointString) {
//       RegExp regex = RegExp(r'([0-9]+\.[0-9]+)');
//       Iterable<Match> matches = regex.allMatches(geoPointString);

//       double latitude = double.parse(matches.elementAt(0).group(0)!);
//       double longitude = double.parse(matches.elementAt(1).group(0)!);

//       return LatLng(latitude, longitude);
//     }).toList();
//   }

//   Future<void> _getUserLocation() async {
//     // Get the user's current location
//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       userLocation = LatLng(position.latitude, position.longitude);
//     });
//   }

//   void _centerMapOnStop(int stopIndex) {
//     LatLng stop = stops[stopIndex];
//     debugPrint('stop: $stop');
//     animatedMapController.centerOnPoint(stop, zoom: 16);
//   }

//   String _constructMapUrl(List<LatLng> stops) {
//     String baseUrl = "https://www.google.com/maps/dir/";

//     String stopsString = stops.map((stop) {
//       return "${stop.latitude},${stop.longitude}";
//     }).join("/");

//     return "$baseUrl$stopsString/";
//   }

//   void _startNavigation(List<LatLng> stops) async {
//     String mapUrl = _constructMapUrl(stops);
//     if (!await launchUrlString(
//       mapUrl,
//       mode: LaunchMode.externalApplication,
//     )) {
//       throw Exception('Could not launch url $mapUrl');
//     }
//   }

//   Future<void> _fetchpathUsingGraphhopper() async {
//     try {
//       // Check if there are enough stops to calculate a route
//       if (stops.isEmpty) {
//         throw Exception("No stops available to calculate the route");
//       }

//       // Build the URL with multiple points
//       String baseUrl = 'https://graphhopper.com/api/1/route';
//       String apiKey = Env.GRAPHHOPPER_API_KEY; // Your GraphHopper API key

//       // Add each stop as a 'point' parameter
//       String pointsQuery = stops.map((stop) {
//         return 'point=${stop.latitude},${stop.longitude}';
//       }).join('&');

//       // Complete the URL
//       final url =
//           '$baseUrl?$pointsQuery&vehicle=car&type=json&points_encoded=false&key=$apiKey';

//       // Make the HTTP GET request
//       final response = await http.get(Uri.parse(url));
//       debugPrint('API response code: ${response.statusCode}');
//       debugPrint('API response headers: ${response.headers}');

//       // If the request was successful, decode the response
//       if (response.statusCode == 200) {
//         Map<String, dynamic> data = jsonDecode(response.body);
//         List<dynamic> paths = data['paths'];

//         // Check if paths are returned
//         if (paths.isNotEmpty) {
//           List<dynamic> points = paths[0]['points']['coordinates'];

//           // Convert points to LatLng and store them in routePoints
//           routePoints = points.map((point) {
//             return LatLng(point[1], point[0]);
//           }).toList();

//           debugPrint('Route points: $routePoints');
//         }
//       } else {
//         throw Exception('Failed to load route: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching route: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar( foregroundColor:Colors.white, backgroundColor:Colors.green,
//           backgroundColor: Colors.green,
//           title: Text(
//             widget.route['routeName'],
//             style: const TextStyle(
//               color: Colors.white,
//             ),
//           ),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               flex: 7,
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : FlutterMap(
//                       mapController: animatedMapController.mapController,
//                       options: MapOptions(
//                         initialCameraFit: CameraFit.bounds(
//                           bounds: LatLngBounds(
//                             stops.first,
//                             stops.last,
//                           ),
//                           forceIntegerZoomLevel: true,
//                         ),
//                         initialCenter: LatLng(
//                           stops.first.latitude,
//                           stops.first.longitude,
//                         ),
//                         initialZoom: 16,
//                       ),
//                       children: [
//                         TileLayer(
//                           urlTemplate:
//                               "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
//                         ),
//                         PolylineLayer(
//                           polylines: [
//                             Polyline(
//                               points: routePoints,
//                               strokeWidth: 4,
//                               color: Colors.green,
//                             ),
//                           ],
//                         ),
//                         AnimatedMarkerLayer(markers: [
//                           if (userLocation != null) // Add user location marker
//                             AnimatedMarker(
//                               rotate: true,
//                               point: userLocation!,
//                               builder: (ctx, animation) {
//                                 return const Icon(
//                                   Icons.circle,
//                                   color: Colors.blue,
//                                   size: 18,
//                                   semanticLabel: 'user-location',
//                                 );
//                               },
//                             ),
//                           ...stops.map((stop) {
//                             return AnimatedMarker(
//                               point: stop,
//                               builder: (_, animation) {
//                                 return const Icon(
//                                   Icons.location_on,
//                                   color: Colors.red,
//                                 );
//                               },
//                             );
//                           }).toList(),
//                         ]),
//                       ],
//                     ),
//             ),
//             Expanded(
//               flex: 3,
//               child: ListView.builder(
//                 itemCount: widget.route['stops'].length,
//                 itemBuilder: (context, index) {
//                   debugPrint(
//                       '${stops[index].latitude}, ${stops[index].longitude}');
//                   var lat = stops[index].latitude;
//                   var lon = stops[index].longitude;
//                   return ListTile(
//                     title: Text(
//                       'Point ${index + 1}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: placeNames.containsKey(index)
//                         // Use the cached place name if available
//                         ? Text(placeNames[index]!)
//                         : FutureBuilder(
//                             future: getPlaceName(lat, lon),
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const Text('Loading..');
//                               } else if (snapshot.hasError) {
//                                 return Text('Error: ${snapshot.error}');
//                               } else {
//                                 String? placeName = snapshot.data;
//                                 // Cache the place name after fetching it
//                                 placeNames[index] = placeName!;
//                                 return Text(placeName);
//                               }
//                             }),
//                     onTap: () {
//                       _centerMapOnStop(index);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton.extended(
//           backgroundColor: Colors.green,
//           onPressed: () {
//             _startNavigation(stops);
//           },
//           label: const Text(
//             'Start\nNavigation',
//             style: TextStyle(
//               color: Colors.white,
//             ),
//           ),
//           icon: const Icon(
//             Icons.navigation_outlined,
//             color: Colors.white,
//           ),
//         ));
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_trip_planner/utilities/env.dart';
import 'package:flutter_map_trip_planner/utilities/location_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with TickerProviderStateMixin {
  List<LatLng> stops = [];
  List<LatLng> routePoints = [];
  List<LatLng> userLocationPath = []; // List to store user's location path
  bool isLoading = true;
  late AnimatedMapController animatedMapController;
  Map<int, String> placeNames = {};

  LatLng? userLocation;
  LatLng? sharedUserLocation;

  @override
  void initState() {
    super.initState();
    animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stops = _parseGeoPoints(widget.route['stops']);
    _fetchpathUsingGraphhopper();
    _getUserLocation();
    _getLocationHistory();
  }

  List<LatLng> _parseGeoPoints(List<dynamic> geoPoints) {
    return geoPoints.map((geoPointString) {
      RegExp regex = RegExp(r'([0-9]+\.[0-9]+)');
      Iterable<Match> matches = regex.allMatches(geoPointString);

      double latitude = double.parse(matches.elementAt(0).group(0)!);
      double longitude = double.parse(matches.elementAt(1).group(0)!);

      return LatLng(latitude, longitude);
    }).toList();
  }

  Future<void> _getUserLocation() async {
    // Get the user's current location
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _centerMapOnStop(int stopIndex) {
    LatLng stop = stops[stopIndex];
    debugPrint('stop: $stop');
    animatedMapController.centerOnPoint(stop, zoom: 16);
  }

  String _constructMapUrl(List<LatLng> stops) {
    String baseUrl = "https://www.google.com/maps/dir/";
    String stopsString = stops.map((stop) {
      return "${stop.latitude},${stop.longitude}";
    }).join("/");
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

  void _getLocationHistory() async {
    // Find the route by routeName
    QuerySnapshot routeQuery = await FirebaseFirestore.instance
        .collection('routes')
        .where('routeName', isEqualTo: widget.route['routeName'])
        .get();

    final routeId = routeQuery.docs.first.id;

    // Listen to real-time updates using snapshots
    FirebaseFirestore.instance
        .collection('routes')
        .doc(routeId)
        .collection('locationHistory')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      List<LatLng> locationHistory = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return LatLng(data['latitude'], data['longitude']);
      }).toList();

      setState(() {
        userLocationPath = locationHistory;
      });
    }, onError: (error) {
      debugPrint("Error fetching location history: $error");
    });
  }

  Future<void> _fetchpathUsingGraphhopper() async {
    try {
      if (stops.isEmpty) {
        throw Exception("No stops available to calculate the route");
      }

      String baseUrl = 'https://graphhopper.com/api/1/route';
      String apiKey = Env.GRAPHHOPPER_API_KEY;

      String pointsQuery = stops.map((stop) {
        return 'point=${stop.latitude},${stop.longitude}';
      }).join('&');

      final url =
          '$baseUrl?$pointsQuery&vehicle=car&type=json&points_encoded=false&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      debugPrint('API response code: ${response.statusCode}');
      debugPrint('API response headers: ${response.headers}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> paths = data['paths'];

        if (paths.isNotEmpty) {
          List<dynamic> points = paths[0]['points']['coordinates'];

          routePoints = points.map((point) {
            return LatLng(point[1], point[0]);
          }).toList();

          debugPrint('Route points: $routePoints');
        }
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          title: Text(
            widget.route['routeName'],
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 7,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: animatedMapController.mapController,
                      options: MapOptions(
                        // initialCameraFit: CameraFit.bounds(
                        //   bounds: LatLngBounds(
                        //     LatLng(stops.first.latitude, stops.first.longitude),
                        //     LatLng(stops.last.latitude, stops.last.longitude),
                        //   ),
                        //   // forceIntegerZoomLevel: true,
                        // ),
                        initialCenter: LatLng(
                          stops.first.latitude,
                          stops.first.longitude,
                        ),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 4,
                              color: Colors.green,
                            ),
                            Polyline(
                              points: userLocationPath,
                              strokeWidth: 4,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        AnimatedMarkerLayer(markers: [
                          if (userLocation != null)
                            AnimatedMarker(
                              rotate: true,
                              point: userLocation!,
                              builder: (ctx, animation) {
                                return const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 16,
                                  semanticLabel: 'user-location',
                                );
                              },
                            ),
                          if (sharedUserLocation != null)
                            AnimatedMarker(
                              rotate: true,
                              point: sharedUserLocation!,
                              builder: (ctx, animation) {
                                return const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.orange,
                                  size: 18,
                                  semanticLabel: 'shared-user-location',
                                );
                              },
                            ),
                          ...stops.map((stop) {
                            return AnimatedMarker(
                              point: stop,
                              builder: (_, animation) {
                                return const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                );
                              },
                            );
                          }),
                        ]),
                      ],
                    ),
            ),
            // Expanded(
            //   flex: 3,
            //   child: ListView.builder(
            //     itemCount: widget.route['stops'].length,
            //     itemBuilder: (context, index) {
            //       debugPrint(
            //           '${stops[index].latitude}, ${stops[index].longitude}');
            //       var lat = stops[index].latitude;
            //       var lon = stops[index].longitude;
            //       return ListTile(
            //         title: Text(
            //           'Point ${index + 1}',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         subtitle: placeNames.containsKey(index)
            //             ? Text(placeNames[index]!)
            //             : FutureBuilder(
            //                 future: getPlaceName(lat, lon),
            //                 builder: (context, snapshot) {
            //                   if (snapshot.connectionState ==
            //                       ConnectionState.waiting) {
            //                     return const Center(
            //                         child: CircularProgressIndicator());
            //                   } else if (snapshot.hasError) {
            //                     return Text('Error: ${snapshot.error}');
            //                   } else {
            //                     final placeName = snapshot.data as String;
            //                     // Cache the place name for future use
            //                     placeNames[index] = placeName;
            //                     return Text(placeName);
            //                   }
            //                 },
            //               ),
            //         onTap: () => _centerMapOnStop(index),
            //       );
            //     },
            //   ),
            // ),
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: widget.route['stops'].length,
                itemBuilder: (context, index) {
                  debugPrint(
                      '${stops[index].latitude}, ${stops[index].longitude}');
                  var lat = stops[index].latitude;
                  var lon = stops[index].longitude;
                  return ListTile(
                    title: Text(
                      'Point ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: placeNames.containsKey(index)
                        ? Text(placeNames[index]!)
                        : FutureBuilder(
                            future: getPlaceName(lat, lon),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                // Use shimmer effect instead of CircularProgressIndicator
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 20.0, // Adjust height as needed
                                    width: double.infinity,
                                    color: Colors.white,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                final placeName = snapshot.data as String;
                                // Cache the place name for future use
                                placeNames[index] = placeName;
                                return Text(placeName);
                              }
                            },
                          ),
                    onTap: () => _centerMapOnStop(index),
                  );
                },
              ),
            ),

            userLocationPath == [] || userLocationPath.isEmpty
                ? const Text('No user Locatiom found!')
                : const Text('User Location found!'),
            ElevatedButton(
              onPressed: () => _startNavigation(stops),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Start Navigation"),
            ),
          ],
        ));
  }
}

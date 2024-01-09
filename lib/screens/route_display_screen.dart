import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late MapController flutterMapController;

  @override
  void initState() {
    super.initState();
    flutterMapController = MapController();
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

  Future<String?> getPlaceName(double latitude, double longitude) async {
    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
      ),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['display_name'];
    } else {
      throw Exception('Failed to load place name');
    }
  }

  String _constructMapUrl() {
    String baseUrl = "https://www.google.com/maps/dir/";
    List<LatLng> stops = _parseGeoPoints(widget.route['stops']);

    String stopsString = stops.map((stop) {
      return "${stop.latitude},${stop.longitude}";
    }).join("/");
    print('$baseUrl$stopsString/');
    return "$baseUrl$stopsString/";
  }

  void _startNavigation() async {
    String mapUrl = _constructMapUrl();
    if (!await launchUrlString(
      mapUrl,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch url $mapUrl');
    }
  }

  void _centerMapOnStop(int stopIndex) {
    LatLng stop = stops[stopIndex];
    print('stop: $stop');
    flutterMapController.camera.center;
    flutterMapController.move(stop, 15.0);
  }

  List<LatLng> stops = [];

  @override
  void didChangeDependencies() {
    stops = _parseGeoPoints(widget.route['stops']);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
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
              child: FlutterMap(
                mapController: flutterMapController,
                options: MapOptions(
                  initialCenter:
                      LatLng(stops.first.latitude, stops.first.longitude),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stops,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: stops.map((stop) {
                      return Marker(
                          width: 30.0,
                          height: 30.0,
                          point: stop,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ));
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: widget.route['stops'].length,
                itemBuilder: (context, index) {
                  print('${stops[index].latitude}, ${stops[index].longitude}');
                  var lat = stops[index].latitude;
                  var lon = stops[index].longitude;
                  return ListTile(
                    title: Text(
                      'Point ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: FutureBuilder(
                        future: getPlaceName(lat, lon),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading..');
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            String? placeName = snapshot.data;
                            return Text(placeName!);
                          }
                        }),
                    onTap: () {
                      _centerMapOnStop(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.amber,
          onPressed: _startNavigation,
          label: const Text(
            'Start\nNavigation',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          icon: const Icon(
            Icons.navigation_outlined,
            color: Colors.white,
          ),
        ));
  }
}

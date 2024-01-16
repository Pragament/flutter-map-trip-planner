import 'dart:convert';
import 'dart:math';

import 'package:flutter_osm_interface/flutter_osm_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

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
  return null;
}

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

List<LatLng> parseGeoPoints(List<dynamic> geoPoints) {
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

double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // Earth's radius in kilometers

  // Convert latitude and longitude from degrees to radians
  double lat1 = radians(point1.latitude);
  double lon1 = radians(point1.longitude);
  double lat2 = radians(point2.latitude);
  double lon2 = radians(point2.longitude);

  // Haversine formula
  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in kilometers
  double distance = earthRadius * c;

  return distance;
}

double radians(double degrees) {
  return degrees * (pi / 180);
}

GeoPoint parseGeoPoint(String geoPointString) {
  RegExp regex = RegExp(r'([0-9]+\.[0-9]+)');
  Iterable<Match> matches = regex.allMatches(geoPointString);

  double latitude = double.parse(matches.elementAt(0).group(0)!);
  double longitude = double.parse(matches.elementAt(1).group(0)!);
  return GeoPoint(
    latitude: latitude,
    longitude: longitude,
  );
}

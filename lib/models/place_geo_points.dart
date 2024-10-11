import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class PlaceGeoPoints {
  GeoPoint selectedPoint;

  PlaceGeoPoints({required this.selectedPoint});

  factory PlaceGeoPoints.fromJson(Map<String, dynamic> data) {
    // Map<String, dynamic> results = data['result'] as Map<String, dynamic>;
    // Map<String, dynamic> geometry = results['geometry'] as Map<String, dynamic>;
    // Map<String, dynamic> location =
    //     geometry['location'] as Map<String, dynamic>;
    GeoPoint geoPoint = GeoPoint(
        latitude: data['result']['geometry']['location']['lat'],
        longitude: data['result']['geometry']['location']['lng']);
    return PlaceGeoPoints(
      selectedPoint: geoPoint,
    );
  }
}

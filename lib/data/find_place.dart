import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/models/place_suggestion.dart';
import 'package:flutter_map_trip_planner/utilities/env.dart';

import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../models/place_geo_points.dart';

class FindPlace {
  Future<List<Suggestion>> placeNameAutocompletion(
      String name, LocationData location) async {
    List<Suggestion> placeSuggestion = [];
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$name&location=${location.latitude}%2C-${location.longitude}&radius=500&types=establishment&key=${Env.GOOGLE_PLACES_API_KEY}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list
        placeSuggestion = result['predictions']
            .map<Suggestion>(
              (place) => Suggestion(
                placeName: place['description'],
                placeId: place['place_id'],
              ),
            )
            .toList();
        return placeSuggestion;
      } else if (result['status'] == 'ZERO_RESULTS') {
        return [];
      } else {
        throw Exception(result['error_message']);
      }
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<PlaceGeoPoints> fetchPlaceGeoPoints(String placeId) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${Env.GOOGLE_PLACES_API_KEY}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      debugPrint("body is: $body");
      PlaceGeoPoints placeGeoPoints = PlaceGeoPoints.fromJson(body);
      return placeGeoPoints;
    } else {
      throw Exception('Failed to fetch place details');
    }
  }
}

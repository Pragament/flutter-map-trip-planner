import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

Future<void> saveUserLocationToFirebase(
    LatLng userLocation, String rtId) async {
  await FirebaseFirestore.instance
      .collection('routes')
      .doc(rtId)
      .collection('locationHistory')
      .doc(DateTime.now().toIso8601String())
      .set({
    'latitude': userLocation.latitude,
    'longitude': userLocation.longitude,
    'timestamp': DateTime.now(),
  }).then((_) {
    debugPrint('User location saved to Firebase.');
  }).catchError((error) {
    debugPrint('Failed to save location to Firebase: $error');
  });
}

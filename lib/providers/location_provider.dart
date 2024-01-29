
import 'package:flutter/material.dart';

import 'package:location/location.dart';

class LocationProvider extends ChangeNotifier
{
  Location location = Location();
  LocationData? currentLocation;

  void updateCurrentLocation(LocationData locationData)
  {
    currentLocation = locationData;
    notifyListeners();
  }
}
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../utilities/location_functions.dart';

class RouteProvider extends ChangeNotifier {
  List<dynamic> userRoutes = [];
  List<Map<String, dynamic>> userStops = [];
  Map<String, List<LatLng>> routeStopsMap = {};
  Map<String, List<String>> routeStopsNames = {};

  void assignRoutes(List<dynamic> routes) {
    userRoutes = [...routes];
    routeStops(userRoutes);
    notifyListeners();
  }

  void addRoute(dynamic data) {
    userRoutes.add(data);
    routeStops(userRoutes);
    notifyListeners();
  }

  void deleteRoute(String routeName) {
    int indexToRemove = userRoutes.indexWhere(
        (element) => element['routeName'].trim() == routeName.trim());
    if (indexToRemove >= 0) {
      userRoutes.removeAt(indexToRemove);
      routeStops(userRoutes);
      notifyListeners();
    }
  }

  void updateRoute(String name, dynamic data) {
    int existingRouteIndex =
        userRoutes.indexWhere((route) => route['routeName'] == name);
    if (existingRouteIndex != -1) {
      userRoutes[existingRouteIndex] = data;
      routeStops(userRoutes);
    }
    notifyListeners();
  }

  void routeStops(List<dynamic> routes) {
    routeStopsMap = {};
    for (var route in routes) {
      List<dynamic> stops = route['stops'];
      List<LatLng> routeStops = parseGeoPoints(stops);
      routeStopsMap[route['routeName']] = routeStops;
    }
    debugPrint('apk: routeStopsMap: $routeStopsMap');
    routeStopNames(routeStopsMap);
    notifyListeners();
  }

  void routeStopNames(Map<String, List<LatLng>> routeStops) {
    routeStopsNames = {};
    routeStops.entries.map((entry) {
      List<String> stopNames = [];
      for (int i = 0; i < entry.value.length; i++) {
        getPlaceName(entry.value[i].latitude, entry.value[i].longitude)
            .then((value) {
          stopNames.add(value!);
          routeStopsNames[entry.key] = stopNames;
          notifyListeners();
        });
      }
    }).toList();
    notifyListeners();
  }

  void assignStops(List<Map<String, dynamic>> stops) {
    userStops = [...stops];
    notifyListeners();
  }

  void addStop(Map<String, dynamic> stop) {
    userStops.add(stop);
    notifyListeners();
  }

  void addStopAt(int index, Map<String, dynamic> stop) {
    userStops.insert(index, stop);
    notifyListeners();
  }

  void deleteStop(int index) {
    userStops.removeAt(index);
    notifyListeners();
  }
}

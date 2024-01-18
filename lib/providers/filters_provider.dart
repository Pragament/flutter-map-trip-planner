import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FiltersProvider extends ChangeNotifier
{

  DateTime? filterDate;
  List<GeoPoint>? stopsIncluded = [];

  void changeFilterDate(DateTime date)
  {
    filterDate = date;
    notifyListeners();
  }

  void includedStops(GeoPoint stop)
  {
    stopsIncluded?.add(stop);
    notifyListeners();
  }

  void excludeStop(int index)
  {
    stopsIncluded?.removeAt(index);
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapSelectionScreen extends StatefulWidget {
  final List<String> existingStops;

  MapSelectionScreen({required this.existingStops});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // MapController mapController = MapController();
  MapController mapController = MapController(
    // 9.75527985137314, 76.64998268216185
    initPosition:
        GeoPoint(latitude: 9.75527985137314, longitude: 76.64998268216185),
    areaLimit: BoundingBox(
      east: 10.4922941,
      north: 47.8084648,
      south: 45.817995,
      west: 5.9559113,
    ),
  );

  List<GeoPoint> selectedStops = [];

  void _saveStops() {
    List<String> newStops =
        selectedStops.map((point) => point.toString()).toList();
    Navigator.of(context).pop(newStops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Stops on Map'),
      ),
      body: OSMFlutter(
        controller: mapController,
        osmOption: const OSMOption(
            // Configure map options if needed

            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveStops,
        child: const Icon(Icons.check),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Stops:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${selectedStops.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

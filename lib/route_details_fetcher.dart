import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/screens/route_display_screen.dart';

class RouteDetailsFetcher extends StatefulWidget {
  final String routeId;
  const RouteDetailsFetcher({super.key, required this.routeId});

  @override
  _RouteDetailsFetcherState createState() => _RouteDetailsFetcherState();
}

class _RouteDetailsFetcherState extends State<RouteDetailsFetcher> {
  Map<String, dynamic>? routeData;

  @override
  void initState() {
    super.initState();
    fetchRouteDetails();
  }

  Future<void> fetchRouteDetails() async {
    // Fetch the route data from Firestore using the routeId
    DocumentSnapshot<Map<String, dynamic>> routeDoc = await FirebaseFirestore
        .instance
        .collection('routes')
        .doc(widget.routeId)
        .get();

    if (routeDoc.exists) {
      setState(() {
        routeData = routeDoc.data();
      });
    } else {
      // Handle the case where the route does not exist
      debugPrint('Route with ID ${widget.routeId} not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (routeData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RouteDetailsScreen(route: routeData!);
  }
}

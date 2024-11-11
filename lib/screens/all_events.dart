import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/data/evens_data.dart';
import 'package:flutter_map_trip_planner/models/event.dart';
import 'package:flutter_map_trip_planner/providers/event_provider.dart';
import 'package:flutter_map_trip_planner/providers/location_provider.dart';
import 'package:flutter_map_trip_planner/screens/event_creation_form.dart';

import 'package:provider/provider.dart';

class EventListView extends StatelessWidget {
  final bool isAdmin;
  EventListView({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    //  final eventProvider = Provider.of<EventProvider>(context);
    // final events = eventProvider.events;
    final cl = Provider.of<LocationProvider>(context).currentLocation;

    return Scaffold(
      body: ListView.builder(
        itemCount: dummyEvents.length,
        itemBuilder: (context, index) {
          final event = dummyEvents[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(event.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.pincode != null) Text("Pincode: ${event.pincode}"),
                  Text("Phone: ${event.phoneNumber}"),
                  Text("Description: ${event.description}"),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventForm(
                        isAdmin: isAdmin,
                        currentLocationData: cl,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/providers/event_provider.dart';
import 'package:flutter_map_trip_planner/providers/location_provider.dart';
import 'package:flutter_map_trip_planner/providers/user_info_provider.dart';
import 'package:flutter_map_trip_planner/screens/event_creation_form.dart';
import 'package:provider/provider.dart';

class EventListView extends StatelessWidget {
  final bool isAdmin;
  EventListView({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final events = eventProvider.events;
    final cl = Provider.of<LocationProvider>(context).currentLocation;

    // Filter events based on user role
    final filteredEvents =
        isAdmin ? events : events.where((event) => event.isApproved).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'All Events' : 'Approved Events'),
      ),
      body: ListView.builder(
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];

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
                  if (isAdmin)
                    Text(
                        "Approval Status: ${event.isApproved ? 'Approved' : 'Unapproved'}"),
                ],
              ),
              trailing: isAdmin
                  ? IconButton(
                      icon: Icon(event.isApproved ? Icons.check : Icons.remove),
                      onPressed: () {
                        // Toggle approval status
                        eventProvider.toggleApproval(event.id);
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventForm(
                              isAdmin: isAdmin,
                              currentLocationData: cl,
                              event: event,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_trip_planner/models/event.dart';
import 'package:flutter_map_trip_planner/screens/event_creation_form.dart';

class EventListView extends StatelessWidget {
  final bool isAdmin;
  final List<dynamic>
      userEvents; // Use List<Map<String, dynamic>> to store events

  EventListView({super.key, required this.isAdmin, required this.userEvents});

  // Function to toggle approval status in Firestore
  Future<void> _toggleApproval(String eventId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({'isApproved': !currentStatus});
      print("Event approval status updated successfully");
    } catch (e) {
      print("Error updating approval status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter events based on user role
    final filteredEvents = isAdmin
        ? userEvents
        : userEvents.where((event) => event['isApproved'] == true).toList();

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
              title: Text(event['title'] ?? 'Untitled Event'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event['pincode'] != null)
                    Text("Pincode: ${event['pincode']}"),
                  Text("Phone: ${event['phoneNumber']}"),
                  Text("Description: ${event['description']}"),
                  if (isAdmin)
                    Text(
                      "Approval Status: ${event['isApproved'] ? 'Approved' : 'Unapproved'}",
                    ),
                ],
              ),
              trailing: isAdmin
                  ? IconButton(
                      icon: Icon(
                          event['isApproved'] ? Icons.check : Icons.remove),
                      onPressed: () {
                        // Toggle approval status
                        _toggleApproval(event['id'], event['isApproved']);
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
                              currentLocationData: event['locationData'],
                              event: Event.fromMap(event),
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

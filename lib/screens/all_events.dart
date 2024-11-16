import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_trip_planner/models/event.dart';
import 'package:flutter_map_trip_planner/screens/event_creation_form.dart';
import 'package:flutter_map_trip_planner/providers/event_provider.dart';

class EventListView extends StatefulWidget {
  final bool isAdmin;
  final List<dynamic> userEvents;
  final bool isLoggedIn; // Indicates whether the user is logged in

  const EventListView({
    super.key,
    required this.isAdmin,
    required this.userEvents,
    required this.isLoggedIn,
  });

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  bool _isLoading = false;
  Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    // Convert and sync events with provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final List<Event> convertedEvents = widget.userEvents.map((eventData) {
        final Map<String, dynamic> eventMap =
            Map<String, dynamic>.from(eventData);
        return Event.fromMap(eventMap);
      }).toList();
      eventProvider.assignEvents(convertedEvents);
    });
  }

  Future<void> _toggleApproval(
    BuildContext context,
    Map<String, dynamic> eventData,
  ) async {
    final String eventId = eventData['id'];
    setState(() {
      _loadingStates[eventId] = true;
    });

    try {
      setState(() {
        eventData['isApproved'] = !eventData['isApproved'];
      });

      final eventRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(eventRef);

        if (!snapshot.exists) {
          throw Exception('Event does not exist!');
        }

        final updateData = {
          'isApproved': eventData['isApproved'],
          'lastModified': FieldValue.serverTimestamp(),
          'modifiedBy': 'admin',
        };

        transaction.update(eventRef, updateData);
      });

      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final updatedEvent = Event.fromMap(Map<String, dynamic>.from(eventData));
      eventProvider.updateEvent(eventId, updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eventData['isApproved']
                ? 'Event approved successfully'
                : 'Event approval revoked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          eventData['isApproved'] = !eventData['isApproved'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[eventId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final filteredEvents = !widget.isLoggedIn
        ? widget.userEvents
            .where((event) => event['isApproved'] == true)
            .toList()
        : widget.isAdmin
            ? widget.userEvents
            : widget.userEvents
                .where((event) => event['isApproved'] == true)
                .toList();

                

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin
            ? 'All Events'
            : widget.isLoggedIn
                ? 'Approved Events'
                : 'Public Events'),
      ),
      body: filteredEvents.isEmpty
          ? const Center(
              child: Text('No events found'),
            )
          : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final eventData = filteredEvents[index];
                final String eventId = eventData['id'];
                final bool isEventLoading = _loadingStates[eventId] ?? false;

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(eventData['title'] ?? 'Untitled Event'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eventData['pincode'] != null)
                          Text("Pincode: ${eventData['pincode']}"),
                        Text("Phone: ${eventData['phoneNumber']}"),
                        Text("Description: ${eventData['description']}"),
                        if (widget.isAdmin)
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: eventData['isApproved']
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text(
                              "Approval Status: ${eventData['isApproved'] ? 'Approved' : 'Pending'}",
                            ),
                          ),
                      ],
                    ),
                    trailing: widget.isAdmin
                        ? isEventLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    eventData['isApproved']
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    key: ValueKey(eventData['isApproved']),
                                    color: eventData['isApproved']
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                onPressed: () {
                                  _toggleApproval(context, eventData);
                                },
                              )
                        : IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventForm(
                                    isAdmin: widget.isAdmin,
                                    currentLocationData:
                                        eventData['locationData'],
                                    event: Event.fromMap(
                                        Map<String, dynamic>.from(eventData)),
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

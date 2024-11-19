import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map_trip_planner/providers/user_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_trip_planner/models/event.dart';
import 'package:flutter_map_trip_planner/screens/event_creation_form.dart';
import 'package:flutter_map_trip_planner/providers/event_provider.dart';

class EventListView extends StatefulWidget {
  final bool isAdmin;
  final bool hasSkippedLogin;

  const EventListView({
    Key? key,
    required this.isAdmin,
    required this.hasSkippedLogin,
  }) : super(key: key);

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _events = [];
  Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _fetchAndSetEvents();
  }

  Future<void> _fetchAndSetEvents() async {
    setState(() {
      _isLoading = true;
    });

    final events = await _fetchEvents(
      isAdmin: widget.isAdmin,
      hasSkippedLogin: widget.hasSkippedLogin,
    );

    setState(() {
      _events = events;
      _isLoading = false;
    });

    // Sync with provider
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final List<Event> convertedEvents = events.map((eventData) {
      final Map<String, dynamic> eventMap =
          Map<String, dynamic>.from(eventData);
      return Event.fromMap(eventMap);
    }).toList();
    eventProvider.assignEvents(convertedEvents);
  }

  Future<void> _toggleApproval(
      BuildContext context, Map<String, dynamic> eventData) async {
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
            content: Text('Error updating event: $e'),
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

  Future<List<Map<String, dynamic>>> _fetchEvents({
    required bool isAdmin,
    required bool hasSkippedLogin,
  }) async {
    try {
      // Case 1: User has skipped login
      if (hasSkippedLogin) {
        // Fetch all public (approved) events
        QuerySnapshot<Map<String, dynamic>> eventSnapshots =
            await FirebaseFirestore.instance
                .collection('events')
                .where('isApproved', isEqualTo: true)
                .get();
        return eventSnapshots.docs.map((doc) => doc.data()).toList();
      }

      // Case 2: User is an admin
      if (isAdmin) {
        // Fetch all events regardless of approval status
        QuerySnapshot<Map<String, dynamic>> eventSnapshots =
            await FirebaseFirestore.instance.collection('events').get();
        return eventSnapshots.docs.map((doc) => doc.data()).toList();
      }

      // Case 3: User is logged in but not an admin
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch user's event IDs
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();

       

        List<String> eventIds =
            List<String>.from(userDoc.get('eventIds') ?? []);

        if (eventIds.isEmpty) return [];

        // Fetch events based on IDs
        QuerySnapshot<Map<String, dynamic>> eventSnapshots =
            await FirebaseFirestore.instance
                .collection('events')
                .where(FieldPath.documentId, whereIn: eventIds)
                .get();

        return eventSnapshots.docs.map((doc) => doc.data()).toList();
      }

      // If none of the conditions match, return an empty list
      return [];
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hasSkippedLogin
            ? 'Public Events'
            : widget.isAdmin
                ? 'All Events'
                : 'Your Events'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No events found'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final eventData = _events[index];
                    final String eventId = eventData['id'];
                    final bool isEventLoading =
                        _loadingStates[eventId] ?? false;

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
                        trailing: widget.hasSkippedLogin
                            ? null
                            : widget.isAdmin
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
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: Icon(
                                            eventData['isApproved']
                                                ? Icons.check_circle
                                                : Icons.pending,
                                            key: ValueKey(
                                                eventData['isApproved']),
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
                                                Map<String, dynamic>.from(
                                                    eventData)),
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

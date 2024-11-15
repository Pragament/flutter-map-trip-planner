import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String userId; // Add userId to associate the event with a specific user
  String title;
  String description;
  bool isOnline;
  String? pincode; // Nullable for online events
  bool hasMultipleStops;
  List<String>? stops; // Nullable and hidden for online events
  String phoneNumber;
  String imgUrl;
  String readMoreUrl;
  String registrationUrl;
  double price;
  RecurrenceRule schedule; // Using RecurrenceRule for RRULE parsing
  TimeOfDay startTime;
  TimeOfDay endTime;
  List<String> tags;
  bool isApproved;

  Event({
    required this.id,
    required this.userId, // Initialize userId
    required this.title,
    required this.description,
    required this.isOnline,
    this.pincode,
    required this.hasMultipleStops,
    this.stops,
    required this.phoneNumber,
    required this.imgUrl,
    required this.readMoreUrl,
    required this.registrationUrl,
    required this.price,
    required String rruleString,
    required this.startTime,
    required this.endTime,
    required this.tags,
    required this.isApproved,
  }) : schedule = RecurrenceRule.fromString(rruleString);

  // Convert Event to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // Include userId in map
      'title': title,
      'description': description,
      'isOnline': isOnline,
      'pincode': pincode,
      'multipleStops': hasMultipleStops,
      'stops': stops,
      'phoneNumber': phoneNumber,
      'imgUrl': imgUrl,
      'readMoreUrl': readMoreUrl,
      'registrationUrl': registrationUrl,
      'price': price,
      'rrule': schedule.toString(), // Save RRULE as a string
      'startTime': '${startTime.hour}:${startTime.minute}', // Save as string
      'endTime': '${endTime.hour}:${endTime.minute}',       // Save as string
      'tags': tags,
      'isApproved': isApproved,
    };
  }

  // Create Event from Map
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      userId: map['userId'], // Retrieve userId from map
      title: map['title'],
      description: map['description'],
      isOnline: map['isOnline'],
      pincode: map['pincode'],
      hasMultipleStops: map['multipleStops'],
      stops: List<String>.from(map['stops'] ?? []),
      phoneNumber: map['phoneNumber'],
      imgUrl: map['imgUrl'],
      readMoreUrl: map['readMoreUrl'],
      registrationUrl: map['registrationUrl'],
      price: map['price'],
      rruleString: map['rrule'],
      startTime: _parseTimeOfDay(map['startTime']),
      endTime: _parseTimeOfDay(map['endTime']),
      tags: List<String>.from(map['tags']),
      isApproved: map['isApproved'],
    );
  }

  // Helper function to parse TimeOfDay from a string
  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Save Event to Firestore
  Future<void> saveToFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('events').doc(id);
    await docRef.set(toMap());
  }

  // Load Event from Firestore
  static Future<Event?> loadFromFirestore(String id) async {
    final docRef = FirebaseFirestore.instance.collection('events').doc(id);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      return Event.fromMap(snapshot.data()!);
    }
    return null;
  }
}

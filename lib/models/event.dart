import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart'; // Assuming you use a package to parse the RRULE string

class Event {
  String id;
  String title;
  String description;
  bool isOnline;
  String? pincode; // Nullable for online events
  bool multipleStops;
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
    required this.title,
    required this.description,
    required this.isOnline,
    this.pincode,
    required this.multipleStops,
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

  // Example method to check if event is online
  bool get hasMultipleStops => multipleStops && !isOnline;
  
 
}

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../models/event.dart';
import '../utilities/location_functions.dart';

class EventProvider extends ChangeNotifier {
  List<Event> events = [];
  Map<String, List<LatLng>> eventStopsMap = {};
  Map<String, List<String>> eventStopNames = {};

  // Adds a new event
  void addEvent(Event event) {
    events.add(event);
    if (event.hasMultipleStops && event.stops != null) {
      updateEventStops(event);
    }
    notifyListeners();
  }

  // Assigns multiple events at once
  void assignEvents(List<Event> newEvents) {
    events = [...newEvents];
    for (var event in events) {
      if (event.hasMultipleStops && event.stops != null) {
        updateEventStops(event);
      }
    }
    notifyListeners();
  }

  // Updates an existing event by ID
  void updateEvent(String id, Event updatedEvent) {
    int existingIndex = events.indexWhere((event) => event.id == id);
    if (existingIndex != -1) {
      events[existingIndex] = updatedEvent;
      if (updatedEvent.hasMultipleStops && updatedEvent.stops != null) {
        updateEventStops(updatedEvent);
      } else {
        eventStopsMap.remove(updatedEvent.id);
        eventStopNames.remove(updatedEvent.id);
      }
      notifyListeners();
    }
  }

  // Deletes an event by ID
  void deleteEvent(String id) {
    int indexToRemove = events.indexWhere((event) => event.id == id);
    if (indexToRemove >= 0) {
      events.removeAt(indexToRemove);
      eventStopsMap.remove(id);
      eventStopNames.remove(id);
      notifyListeners();
    }
  }

  // Parses stops for a single event and stores them in eventStopsMap
  void updateEventStops(Event event) {
    List<LatLng> eventStops = parseGeoPoints(event.stops!);
    eventStopsMap[event.id] = eventStops;
    updateEventStopNames(event.id, eventStops);
  }

  // Gets names for each stop location and updates eventStopNames
  void updateEventStopNames(String eventId, List<LatLng> stops) {
    List<String> stopNames = [];
    for (var stop in stops) {
      getPlaceName(stop.latitude, stop.longitude).then((placeName) {
        if (placeName != null) {
          stopNames.add(placeName);
          eventStopNames[eventId] = stopNames;
          notifyListeners();
        }
      });
    }
  }

  // Adds a new stop to a specific event by ID
  void addStopToEvent(String eventId, LatLng newStop) {
    int eventIndex = events.indexWhere((event) => event.id == eventId);
    if (eventIndex != -1 && events[eventIndex].hasMultipleStops) {
      events[eventIndex].stops?.add('${newStop.latitude},${newStop.longitude}');
      updateEventStops(events[eventIndex]);
      notifyListeners();
    }
  }

  // Deletes a stop from a specific event by index
  void deleteStopFromEvent(String eventId, int stopIndex) {
    int eventIndex = events.indexWhere((event) => event.id == eventId);
    if (eventIndex != -1 && events[eventIndex].stops != null) {
      events[eventIndex].stops?.removeAt(stopIndex);
      updateEventStops(events[eventIndex]);
      notifyListeners();
    }
  }

  void toggleApproval(String eventId) {
    final event = events.firstWhere((event) => event.id == eventId);
    event.isApproved = !event.isApproved;
    notifyListeners(); // Notify listeners to update the UI
  }
}

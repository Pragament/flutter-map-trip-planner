import 'package:flutter/material.dart';

import '../models/event.dart';

List<Event> dummyEvents = [
  Event(
    id: '1',
    title: 'Online Coding Workshop',
    description: 'A virtual coding workshop for beginners.',
    isOnline: true,
    pincode: null,
    multipleStops: false,
    stops: null,
    phoneNumber: '1234567890',
    imgUrl: 'https://example.com/image1.jpg',
    readMoreUrl: 'https://example.com/workshop',
    registrationUrl: 'https://example.com/register',
    price: 0.0,
    rruleString: 'RRULE:FREQ=WEEKLY;BYDAY=MO;INTERVAL=1;UNTIL=20241231',
    startTime: TimeOfDay(hour: 10, minute: 0), // 10:00 AM
    endTime: TimeOfDay(hour: 12, minute: 0), // 12:00 PM
    tags: ['coding', 'workshop', 'online'],
    isApproved: true,
  ),
  Event(
    id: '2',
    title: 'City Marathon',
    description: 'An exciting marathon event across the city.',
    isOnline: false,
    pincode: '123456',
    multipleStops: true,
    stops: ['Start Point', 'Checkpoint 1', 'Checkpoint 2', 'Finish Line'],
    phoneNumber: '0987654321',
    imgUrl: 'https://example.com/image2.jpg',
    readMoreUrl: 'https://example.com/marathon',
    registrationUrl: 'https://example.com/register',
    price: 25.0,
    rruleString: 'RRULE:FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=22;UNTIL=20250922',
    startTime: TimeOfDay(hour: 6, minute: 0), // 6:00 AM
    endTime: TimeOfDay(hour: 12, minute: 0), // 12:00 PM
    tags: ['marathon', 'sports', 'outdoor'],
    isApproved: true,
  ),
  Event(
    id: '3',
    title: 'Art Exhibition',
    description: 'An exhibition showcasing local artists.',
    isOnline: false,
    pincode: '654321',
    multipleStops: false,
    stops: null,
    phoneNumber: '1112223333',
    imgUrl: 'https://example.com/image3.jpg',
    readMoreUrl: 'https://example.com/art-exhibition',
    registrationUrl: 'https://example.com/register',
    price: 15.0,
    rruleString: 'RRULE:FREQ=DAILY;INTERVAL=1;UNTIL=20240930',
    startTime: TimeOfDay(hour: 10, minute: 0), // 10:00 AM
    endTime: TimeOfDay(hour: 18, minute: 0), // 6:00 PM
    tags: ['art', 'exhibition', 'gallery'],
    isApproved: true,
  ),
  Event(
    id: '4',
    title: 'Mountain Hike Adventure',
    description: 'A weekend adventure hiking the mountains.',
    isOnline: false,
    pincode: '789456',
    multipleStops: true,
    stops: ['Base Camp', 'First Peak', 'Summit'],
    phoneNumber: '2223334444',
    imgUrl: 'https://example.com/image4.jpg',
    readMoreUrl: 'https://example.com/mountain-hike',
    registrationUrl: 'https://example.com/register',
    price: 50.0,
    rruleString: 'RRULE:FREQ=MONTHLY;BYMONTHDAY=15;UNTIL=20241215',
    startTime: TimeOfDay(hour: 5, minute: 0), // 5:00 AM
    endTime: TimeOfDay(hour: 16, minute: 0), // 4:00 PM
    tags: ['hiking', 'adventure', 'outdoors'],
    isApproved: false,
  ),
  Event(
    id: '5',
    title: 'Startup Networking Event',
    description: 'Meet and network with startups and entrepreneurs.',
    isOnline: true,
    pincode: null,
    multipleStops: false,
    stops: null,
    phoneNumber: '5556667777',
    imgUrl: 'https://example.com/image5.jpg',
    readMoreUrl: 'https://example.com/startup-event',
    registrationUrl: 'https://example.com/register',
    price: 10.0,
    rruleString: 'RRULE:FREQ=MONTHLY;BYMONTHDAY=10;UNTIL=20241210',
    startTime: TimeOfDay(hour: 18, minute: 0), // 6:00 PM
    endTime: TimeOfDay(hour: 21, minute: 0), // 9:00 PM
    tags: ['networking', 'business', 'startups'],
    isApproved: true,
  ),
];

import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/screens/route_add_stop.dart';
import 'package:flutter_map_trip_planner/screens/route_creation_screen.dart';
import 'package:location/location.dart';

class EventForm extends StatefulWidget {
  final bool isAdmin;

  EventForm({required this.isAdmin});

  @override
  _EventFormState createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pincodeController;
  late TextEditingController _idController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _imgUrlController;
  late TextEditingController _readMoreUrlController;
  late TextEditingController _registrationUrlController;
  late TextEditingController _priceController;
  late TextEditingController _rruleController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _tagsController;

  bool _isOnlineEvent = false;
  bool _isApprovedEvent = false;
  List<String> _stops = [];
  late LocationData _sampleLocationData;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _pincodeController = TextEditingController();
    _idController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _imgUrlController = TextEditingController();
    _readMoreUrlController = TextEditingController();
    _registrationUrlController = TextEditingController();
    _priceController = TextEditingController();
    _rruleController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _tagsController = TextEditingController();

    _rruleController.text =
        'RRULE:FREQ=MONTHLY;BYMONTHDAY=22;INTERVAL=1;UNTIL=20240823';

    Map<String, dynamic> sampleLocationMap = {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'accuracy': 5.0,
      'altitude': 10.0,
      'speed': 0.0,
      'speed_accuracy': 0.0,
      'heading': 0.0,
      'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
      'isMock': false,
      'verticalAccuracy': 5.0,
      'headingAccuracy': 1.0,
      'elapsedRealtimeNanos': 0.0,
      'elapsedRealtimeUncertaintyNanos': 0.0,
      'satelliteNumber': 0,
      'provider': 'gps',
    };

    _sampleLocationData = LocationData.fromMap(sampleLocationMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        title: const Text('Create/Edit Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                SwitchListTile(
                  title: const Text('Online Event'),
                  value: _isOnlineEvent,
                  onChanged: (value) {
                    setState(() {
                      _isOnlineEvent = value;
                    });
                  },
                ),
                if (!_isOnlineEvent)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _pincodeController,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16.0),
                      const Text('Stops'),
                      // ConstrainedBox(
                      //   constraints: BoxConstraints(maxHeight: 500.0),
                      //   child: RouteCreationScreen(
                      //     currentLocationData: _sampleLocationData,
                      //     locationName: "sample location data",
                      //     selectedTags: ['tag1', 'tag2'],
                      //     allTags: ['tag1', 'tag2', 'tag3'],
                      //   ),
                      // ),
                    ],
                  ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Event ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _imgUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _readMoreUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Read More URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _registrationUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Registration URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _rruleController,
                  decoration: const InputDecoration(
                    labelText: 'RRULE',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (widget.isAdmin)
                  SwitchListTile(
                    title: const Text('Approved Event'),
                    value: _isApprovedEvent,
                    onChanged: (value) {
                      setState(() {
                        _isApprovedEvent = value;
                      });
                    },
                  ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Form submission logic here
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pincodeController.dispose();
    _idController.dispose();
    _phoneNumberController.dispose();
    _imgUrlController.dispose();
    _readMoreUrlController.dispose();
    _registrationUrlController.dispose();
    _priceController.dispose();
    _rruleController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}

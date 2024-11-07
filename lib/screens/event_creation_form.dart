import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/providers/loading_provider.dart';
import 'package:flutter_map_trip_planner/providers/route_provider.dart';
import 'package:flutter_map_trip_planner/screens/route_add_stop.dart';

import 'package:flutter_map_trip_planner/utilities/location_functions.dart';
import 'package:flutter_map_trip_planner/widgets/tags_selection_dialog.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_osm_interface/flutter_osm_interface.dart' as osm;
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:rrule_generator/rrule_generator.dart';

import 'package:textfield_tags/textfield_tags.dart';

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class EventForm extends StatefulWidget {
  final bool isAdmin;

  EventForm(
      {required this.currentLocationData, required this.isAdmin, super.key});
  late LocationData? currentLocationData;

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
  final List<TextEditingController> _stopControllers = [];
  final List<TextEditingController> _stopNameControllers = [];
  List<Map<String, dynamic>> displayedUserAddedStops = [];
  List<Map<String, dynamic>> copy = [];
  ValueNotifier<String?> generatedRRuleNotifier = ValueNotifier(null);

  List<LatLng> stops = [];
  List<String> tags = [];
  late TextfieldTagsController _textfieldTagsController;
  late flutterMap.MapController flutterMapController;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _frequency = 'daily'; // Example frequency value
  int _interval = 1;
  int _dayOfMonth = 1;
  DateTime _untilDate = DateTime.now().add(const Duration(days: 365));
  DateTime _startDate = DateTime.now();

  bool _isOnlineEvent = false;
  bool _isApprovedEvent = false;

  final List<FocusNode> _stopFocusNodes = [FocusNode()];
  late flutterMap.Marker marker;

  String savedRRule =
      'RRULE:FREQ=MONTHLY;BYMONTHDAY=22;INTERVAL=1;UNTIL=20240823';

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

    _textfieldTagsController = TextfieldTagsController();
    marker = flutterMap.Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(widget.currentLocationData!.latitude!,
          widget.currentLocationData!.longitude!),
      child: const Icon(
        Icons.circle_sharp,
        color: Colors.blue,
        size: 16,
      ),
    );

    osm.GeoPoint geoPoint = osm.GeoPoint(
        latitude: widget.currentLocationData!.latitude!,
        longitude: widget.currentLocationData!.longitude!);
    //  _stopNameControllers.add(TextEditingController(text: widget.locationName));
    _stopControllers.add(TextEditingController(text: geoPoint.toString()));
    flutterMapController = flutterMap.MapController();
    stops.add(LatLng(widget.currentLocationData!.latitude!,
        widget.currentLocationData!.longitude!));
  }

  void _removeStop(int index) {
    setState(() {
      if (index >= 0 && index < _stopControllers.length) {
        _stopNameControllers.removeAt(index);
        _stopControllers.removeAt(index);
        stops.removeAt(index);
        _stopFocusNodes.removeAt(index);
      }
    });
  }

  Future<void> _fetchUserAddedStops() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<dynamic> userAddedStopsData =
          Provider.of<RouteProvider>(context, listen: false).userStops;
      print('USER ADDED STOPS : $userAddedStopsData');
      displayedUserAddedStops = userAddedStopsData.map((stopData) {
        return {
          'stop': stopData['stop'],
          'selectedPoint': stopData['selectedPoint'],
        };
      }).toList();
      copy = userAddedStopsData.map((stopData) {
        return {
          'stop': stopData['stop'],
          'selectedPoint': stopData['selectedPoint']
        };
      }).toList();
    }
    setState(() {
      displayedUserAddedStops.removeWhere((element) =>
          (element['selectedPoint'].toString().isEmpty ||
              element['selectedPoint'] == null));
      displayedUserAddedStops = displayedUserAddedStops;
    });
  }

  //funtion to pick time from timepicker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  // Generate RRULE based on user input

  void _editRRule() async {
    final rrule = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: SingleChildScrollView(
          child: RRuleGenerator(
            initialRRule: generatedRRuleNotifier.value ?? '',
            config: RRuleGeneratorConfig(),
            textDelegate: const EnglishRRuleTextDelegate(),
            onChange: (rrule) {
              generatedRRuleNotifier.value = rrule;
            },
          ),
        ),
        actions: <Widget>[
          const Text(
            'Don\'t skip stop conditions or else you will end up with error!',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final rrule = generatedRRuleNotifier.value;
              Navigator.of(context).pop(rrule);
            },
          ),
        ],
      ),
    );
    if (rrule != null) {
      generatedRRuleNotifier.value = rrule;
      setState(() {
        savedRRule = rrule;
      });
    }
  }

//save tags
  void addTag(String tag) {
    if (tag.isNotEmpty) {
      setState(() {
        tags.add(tag);
      });
    }
  }

  //remove tag
  void removeTag(String tag) {
    if (tag.isNotEmpty) {
      setState(() {
        tags.remove(tag);
      });
    }
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
                  SizedBox(
                    child: Column(
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
                        const Center(
                          child: Text(
                            'STOPS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_stopNameControllers.isNotEmpty)
                          SizedBox(
                            child: ReorderableListView.builder(
                              shrinkWrap: true,
                              itemCount: _stopNameControllers.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  key: ValueKey(index),
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(Icons.reorder),
                                      SizedBox(
                                        height: 60,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.70,
                                        child: TextField(
                                          readOnly: true,
                                          // enabled: false,
                                          controller:
                                              _stopNameControllers[index],
                                          decoration: InputDecoration(
                                              labelText: 'Stop ${index + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                              suffixIcon: IconButton(
                                                onPressed: () async {
                                                  final selectedPoint =
                                                      await showSimplePickerLocation(
                                                    context: context,
                                                    isDismissible: true,
                                                    title: "Select Stop",
                                                    textConfirmPicker: "pick",
                                                    zoomOption:
                                                        const ZoomOption(
                                                      initZoom: 15,
                                                    ),
                                                    initPosition: parseGeoPoint(
                                                        _stopControllers[index]
                                                            .text),
                                                    radius: 15.0,
                                                  );
                                                  if (selectedPoint != null) {
                                                    osm.GeoPoint geoPoint =
                                                        selectedPoint;
                                                    double latitude =
                                                        geoPoint.latitude;
                                                    double longitude =
                                                        geoPoint.longitude;
                                                    setState(() {
                                                      stops[index] = LatLng(
                                                          latitude, longitude);
                                                    });
                                                    _stopNameControllers[index]
                                                            .text =
                                                        (await getPlaceName(
                                                            latitude,
                                                            longitude))!;
                                                    _stopControllers[index]
                                                            .text =
                                                        geoPoint.toString();
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.gps_not_fixed),
                                              )),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () => _removeStop(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onReorder: (int oldIndex, int newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex--;
                                  }
                                  TextEditingController stopNameController =
                                      _stopNameControllers.removeAt(oldIndex);
                                  TextEditingController stopController =
                                      _stopControllers.removeAt(oldIndex);
                                  LatLng stop = stops.removeAt(oldIndex);
                                  _stopNameControllers.insert(
                                      newIndex, stopNameController);
                                  _stopControllers.insert(
                                      newIndex, stopController);
                                  stops.insert(newIndex, stop);
                                });
                              },
                            ),
                          ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _fetchUserAddedStops();
                              osm.GeoPoint selectedPoint = osm.GeoPoint(
                                latitude: widget.currentLocationData!.latitude!,
                                longitude:
                                    widget.currentLocationData!.longitude!,
                              );
                              String? updatedStopName;
                              List<dynamic> data = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => RouteAddStopScreen(
                                    currentLocationData:
                                        widget.currentLocationData!,
                                    displayedUserAddedStops:
                                        displayedUserAddedStops,
                                  ),
                                ),
                              );
                              updatedStopName = data[0]?.toString() ?? '';
                              selectedPoint = data[1] as osm.GeoPoint;
                              if (updatedStopName.trim().isEmpty) {
                                updatedStopName = await getPlaceName(
                                  selectedPoint.latitude,
                                  selectedPoint.longitude,
                                );
                              }
                              String updatedStop = selectedPoint.toString();
                              setState(() {
                                _stopNameControllers.add(TextEditingController(
                                    text: updatedStopName));
                                _stopControllers.add(
                                    TextEditingController(text: updatedStop));
                                _stopFocusNodes.add(FocusNode());
                                stops.add(LatLng(selectedPoint.latitude,
                                    selectedPoint.longitude));
                              });
                            }, // _addStop
                            child: const Text('Add Stop'),
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              flutterMap.FlutterMap(
                                mapController: flutterMapController,
                                options: flutterMap.MapOptions(
                                  initialCenter: LatLng(
                                    widget.currentLocationData!.latitude!,
                                    widget.currentLocationData!.longitude!,
                                  ),
                                  initialZoom: 14.0,
                                ),
                                children: [
                                  flutterMap.TileLayer(
                                    urlTemplate:
                                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  ),
                                  flutterMap.PolylineLayer(
                                    polylines: [
                                      flutterMap.Polyline(
                                        points: stops,
                                        strokeWidth: 4,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                  flutterMap.MarkerLayer(
                                    markers: [
                                      for (int i = 0; i < stops.length; i++)
                                        flutterMap.Marker(
                                          width: 80.0,
                                          height: 80.0,
                                          point: stops[i],
                                          child: Stack(
                                            children: [
                                              const Positioned(
                                                top: 17.4,
                                                left: 28,
                                                child: Icon(
                                                  Icons.location_on,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Positioned(
                                                top: 27.4,
                                                left: 25,
                                                child: Text(
                                                  '${i + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      marker,
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Consumer<LoadingProvider>(
                                  builder: (BuildContext context,
                                      LoadingProvider loadingProvider,
                                      Widget? child) {
                                    return FloatingActionButton(
                                      onPressed: () async {
                                        loadingProvider
                                            .changeRouteCreationUpdateLocationState(
                                                true);
                                        widget.currentLocationData =
                                            await fetchCurrentLocation();
                                        loadingProvider
                                            .changeRouteCreationUpdateLocationState(
                                                false);
                                        print(
                                            'Updated Location  ==>  $widget.currentLocationData');
                                        setState(() {
                                          marker = flutterMap.Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(
                                                widget.currentLocationData!
                                                    .latitude!,
                                                widget.currentLocationData!
                                                    .longitude!),
                                            child: const Icon(
                                              Icons.circle_sharp,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                          );
                                        });
                                        flutterMapController.move(
                                            LatLng(
                                              widget.currentLocationData!
                                                  .latitude!,
                                              widget.currentLocationData!
                                                  .longitude!,
                                            ),
                                            14);
                                      },
                                      child: loadingProvider
                                              .routeCreationUpdateLocation
                                          ? const Center(
                                              child: SizedBox(
                                                width: 25,
                                                height: 25,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.location_searching,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                ValueListenableBuilder<String?>(
                  valueListenable: generatedRRuleNotifier,
                  builder: (context, savedRRule, child) {
                    return savedRRule != null
                        ? Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 1,
                                color: Colors.black,
                              ),
                            ),
                            child: Text(
                              'Generated rrule: $savedRRule',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: _editRRule,
                  child: const Text('Edit RRule'),
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () => _selectTime(context, true),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () => _selectTime(context, false),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _endTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Tags',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                addTag(_tagsController.text);
                                _tagsController.clear();
                              },
                              child: const Text("Add Tag"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (tags.isNotEmpty)
                        SizedBox(
                          height: 50,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                ...tags.map((tag) {
                                  return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5))),
                                          child: Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  tag,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                IconButton(
                                                    onPressed: () {
                                                      removeTag(tag);
                                                    },
                                                    icon: const Icon(
                                                      Icons.dangerous_outlined,
                                                      color: Colors.white,
                                                    ))
                                              ],
                                            ),
                                          )));
                                }),
                              ],
                            ),
                          ),
                        ),
                    ],
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

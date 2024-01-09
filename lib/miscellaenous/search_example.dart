// // ignore_for_file: use_build_context_synchronously
//
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
// import 'package:permission_handler/permission_handler.dart' as ph;
// import 'package:location/location.dart';
//
// class LocationAppExample extends StatefulWidget {
//   const LocationAppExample({super.key, required this.currentLocationData});
//
//   final LocationData? currentLocationData;
//
//   @override
//   State<StatefulWidget> createState() => _LocationAppExampleState();
// }
//
// class _LocationAppExampleState extends State<LocationAppExample> {
//   // ValueNotifier<GeoPoint?> notifier = ValueNotifier(null);
//   late GeoPoint selectedLocation;
//   @override
//   void initState() {
//     super.initState();
//     _checkLocationPermission();
//   }
//
//   Future<void> _checkLocationPermission() async {
//     ph.PermissionStatus status = await ph.Permission.locationWhenInUse.status;
//     // print("Status is: $status");
//     // if (status.isDenied) {
//     //   await ph.Permission.locationWhenInUse.request();
//     //   status = await ph.Permission.locationWhenInUse.status;
//     // }
//
//     if (status.isGranted) {
//       // Location location = Location();
//       // LocationData locationData = await location.getLocation();
//       selectedLocation = GeoPoint(
//         latitude: widget.currentLocationData!.latitude!,
//         longitude: widget.currentLocationData!.longitude!,
//       );
//       // notifier.value = userLocation;
//       // print("Notifier value: ${notifier.value}");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Location Picker"),
//         backgroundColor: Colors.amber,
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             var p = await showSimplePickerLocation(
//               context: context,
//               isDismissible: true,
//               title: "Select Stop",
//               textConfirmPicker: "pick",
//               zoomOption: const ZoomOption(
//                 initZoom: 15,
//               ),
//               initPosition: selectedLocation,
//               // initPosition: notifier.value ??
//               //     GeoPoint(
//               //       // 9.75527985137314, 76.64998268216185
//               //       latitude: 9.75527985137314,
//               //       longitude: 76.64998268216185,
//               //     ),
//               radius: 15.0,
//             );
//             if (p != null) {
//               selectedLocation = p;
//               Navigator.pop(context, p);
//             }
//           },
//           child: const Text("Open Map"),
//         ),
//       ),
//     );
//   }
// }
//
// class SearchPage extends StatefulWidget {
//   const SearchPage({super.key});
//
//   @override
//   State<StatefulWidget> createState() => _SearchPageState();
// }
//
// class _SearchPageState extends State<SearchPage> {
//   late TextEditingController textEditingController = TextEditingController();
//   late PickerMapController controller = PickerMapController(
//     initMapWithUserPosition: const UserTrackingOption(),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     textEditingController.addListener(textOnChanged);
//   }
//
//   void textOnChanged() {
//     controller.setSearchableText(textEditingController.text);
//   }
//
//   @override
//   void dispose() {
//     textEditingController.removeListener(textOnChanged);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomPickerLocation(
//       controller: controller,
//       topWidgetPicker: Padding(
//         padding: const EdgeInsets.only(
//           top: 56,
//           left: 8,
//           right: 8,
//         ),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 PointerInterceptor(
//                   child: TextButton(
//                     style: TextButton.styleFrom(),
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: const Icon(
//                       Icons.arrow_back_ios,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: PointerInterceptor(
//                     child: TextField(
//                       controller: textEditingController,
//                       onEditingComplete: () async {
//                         FocusScope.of(context).requestFocus(FocusNode());
//                       },
//                       decoration: InputDecoration(
//                         prefixIcon: const Icon(
//                           Icons.search,
//                           color: Colors.black,
//                         ),
//                         suffix: ValueListenableBuilder<TextEditingValue>(
//                           valueListenable: textEditingController,
//                           builder: (ctx, text, child) {
//                             if (text.text.isNotEmpty) {
//                               return child!;
//                             }
//                             return const SizedBox.shrink();
//                           },
//                           child: InkWell(
//                             focusNode: FocusNode(),
//                             onTap: () {
//                               textEditingController.clear();
//                               controller.setSearchableText("");
//                               FocusScope.of(context).requestFocus(FocusNode());
//                             },
//                             child: const Icon(
//                               Icons.close,
//                               size: 16,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         focusColor: Colors.black,
//                         filled: true,
//                         hintText: "search",
//                         border: InputBorder.none,
//                         enabledBorder: InputBorder.none,
//                         fillColor: Colors.grey[300],
//                         errorBorder: const OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.red),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 8,
//             ),
//             const TopSearchWidget()
//           ],
//         ),
//       ),
//       bottomWidgetPicker: Positioned(
//         bottom: 12,
//         right: 8,
//         child: PointerInterceptor(
//           child: FloatingActionButton(
//             onPressed: () async {
//               GeoPoint p = await controller.selectAdvancedPositionPicker();
//               Navigator.pop(context, p);
//             },
//             child: const Icon(Icons.arrow_forward),
//           ),
//         ),
//       ),
//       pickerConfig: const CustomPickerLocationConfig(
//         zoomOption: ZoomOption(
//           initZoom: 8,
//         ),
//       ),
//     );
//   }
// }
//
// class TopSearchWidget extends StatefulWidget {
//   const TopSearchWidget({super.key});
//
//   @override
//   State<StatefulWidget> createState() => _TopSearchWidgetState();
// }
//
// class _TopSearchWidgetState extends State<TopSearchWidget> {
//   late PickerMapController controller;
//   ValueNotifier<GeoPoint?> notifierGeoPoint = ValueNotifier(null);
//   ValueNotifier<bool> notifierAutoCompletion = ValueNotifier(false);
//
//   late StreamController<List<SearchInfo>> streamSuggestion = StreamController();
//   late Future<List<SearchInfo>> _futureSuggestionAddress;
//   String oldText = "";
//   Timer? _timerToStartSuggestionReq;
//   final Key streamKey = const Key("streamAddressSug");
//
//   @override
//   void initState() {
//     super.initState();
//     controller = CustomPickerLocation.of(context);
//     controller.searchableText.addListener(onSearchableTextChanged);
//   }
//
//   void onSearchableTextChanged() async {
//     final v = controller.searchableText.value;
//     if (v.length > 3 && oldText != v) {
//       oldText = v;
//       if (_timerToStartSuggestionReq != null &&
//           _timerToStartSuggestionReq!.isActive) {
//         _timerToStartSuggestionReq!.cancel();
//       }
//       _timerToStartSuggestionReq =
//           Timer.periodic(const Duration(seconds: 3), (timer) async {
//         await suggestionProcessing(v);
//         timer.cancel();
//       });
//     }
//     if (v.isEmpty) {
//       await reInitStream();
//     }
//   }
//
//   Future reInitStream() async {
//     notifierAutoCompletion.value = false;
//     await streamSuggestion.close();
//     setState(() {
//       streamSuggestion = StreamController();
//     });
//   }
//
//   Future<void> suggestionProcessing(String addr) async {
//     notifierAutoCompletion.value = true;
//     _futureSuggestionAddress = addressSuggestion(
//       addr,
//       limitInformation: 5,
//     );
//     _futureSuggestionAddress.then((value) {
//       streamSuggestion.sink.add(value);
//     });
//   }
//
//   @override
//   void dispose() {
//     controller.searchableText.removeListener(onSearchableTextChanged);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<bool>(
//       valueListenable: notifierAutoCompletion,
//       builder: (ctx, isVisible, child) {
//         return AnimatedContainer(
//           duration: const Duration(
//             milliseconds: 500,
//           ),
//           height: isVisible ? MediaQuery.of(context).size.height / 4 : 0,
//           child: Card(
//             child: child!,
//           ),
//         );
//       },
//       child: StreamBuilder<List<SearchInfo>>(
//         stream: streamSuggestion.stream,
//         key: streamKey,
//         builder: (ctx, snap) {
//           if (snap.hasData) {
//             return ListView.builder(
//               itemExtent: 50.0,
//               itemBuilder: (ctx, index) {
//                 return PointerInterceptor(
//                   child: ListTile(
//                     title: Text(
//                       snap.data![index].address.toString(),
//                       maxLines: 1,
//                       overflow: TextOverflow.fade,
//                     ),
//                     onTap: () async {
//                       /// go to location selected by address
//                       controller.goToLocation(
//                         snap.data![index].point!,
//                       );
//
//                       /// hide suggestion card
//                       notifierAutoCompletion.value = false;
//                       await reInitStream();
//                       FocusScope.of(context).requestFocus(
//                         FocusNode(),
//                       );
//                     },
//                   ),
//                 );
//               },
//               itemCount: snap.data!.length,
//             );
//           }
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Card(
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }
//           return const SizedBox();
//         },
//       ),
//     );
//   }
// }

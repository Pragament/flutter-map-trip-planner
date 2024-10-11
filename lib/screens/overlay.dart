import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:share_plus/share_plus.dart';

class OverLayScreen extends StatefulWidget {
  const OverLayScreen({super.key});

  @override
  State<OverLayScreen> createState() => _OverLayScreenState();
}

class _OverLayScreenState extends State<OverLayScreen> {
  String nextStop = 'Getting Location ...';
  String routeId = "";
  final String shareUrlBase = 'https://pragament.com/map-trip-tracker/';

  // Listen to overlay data stream
  StreamSubscription nextStopStreamSubscription =
      FlutterOverlayWindow.overlayListener.listen((event) {});

  Future<void> shareLocationHistory() async {
    // Construct the shareable link
    String shareableLink = '$shareUrlBase$routeId';

    // Use url_launcher or any sharing plugin to share the link
    Share.share(shareableLink);

    // nextStopStreamSubscription.cancel();
    await FlutterOverlayWindow.shareData('Share your route: $shareableLink');
  }

  @override
  Widget build(BuildContext context) {
    nextStopStreamSubscription.onData((data) {
      setState(() {
        debugPrint('apk: NEAREST STOP : $data');
        routeId = data['routeId'];
        nextStop = data['nextStop'];
      });
    });

    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.route_sharp),
              IconButton(
                icon: const Icon(Icons.share, weight: 800),
                onPressed: () async {
                  await shareLocationHistory();
                },
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nextStop,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nextStopStreamSubscription.cancel();
    super.dispose();
  }
}

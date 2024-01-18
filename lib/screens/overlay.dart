import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverLayScreen extends StatefulWidget {
  const OverLayScreen({super.key});

  @override
  State<OverLayScreen> createState() => _OverLayScreenState();
}

class _OverLayScreenState extends State<OverLayScreen> {

  String nextStop = 'Getting Location ...';

  StreamSubscription nextStopStreamSubscription =
      FlutterOverlayWindow.overlayListener.listen((event) {});

  @override
  Widget build(BuildContext context) {
    nextStopStreamSubscription.onData((data) {
      setState(() {
        print('NEAREST STOP : $data');
        nextStop = data;
      });
    });
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Icon(Icons.route_sharp),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              nextStop,
              maxLines: 3,    // 3
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
}

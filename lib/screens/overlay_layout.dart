import 'package:flutter/material.dart';
import 'package:flutter_map_trip_planner/screens/overlay.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayLayout extends StatelessWidget {
  const OverlayLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Top Row with Title and Close Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                'Nearest Stop',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: FlutterOverlayWindow.closeOverlay,
              icon: Icon(
                Icons.cancel_rounded,
                size: 25,
              ),
            ),
          ],
        ),
        // Expanded area with overlay content
        Expanded(child: OverLayScreen()),
      ],
    );
  }
}

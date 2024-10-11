import 'package:flutter/material.dart';

class DeleteStopScreen extends StatefulWidget {
  final List<String> stops;
  final Function(String) onDeleteStop;

  const DeleteStopScreen({
    super.key,
    required this.stops,
    required this.onDeleteStop,
  });

  @override
  _DeleteStopScreenState createState() => _DeleteStopScreenState();
}

class _DeleteStopScreenState extends State<DeleteStopScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        title: const Text('Delete Stop'),
      ),
      body: ListView.builder(
        itemCount: widget.stops.length,
        itemBuilder: (context, index) {
          String stop = widget.stops[index];
          return ListTile(
            title: Text(stop),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                widget.onDeleteStop(stop);
                setState(() {
                  widget.stops.remove(stop);
                });
              },
            ),
          );
        },
      ),
    );
  }
}

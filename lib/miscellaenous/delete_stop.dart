import 'package:flutter/material.dart';

class DeleteStopScreen extends StatefulWidget {
  final List<String> stops;
  final Function(String) onDeleteStop;

  const DeleteStopScreen(
      {required this.stops, required this.onDeleteStop, Key? key})
      : super(key: key);

  @override
  _DeleteStopScreenState createState() => _DeleteStopScreenState();
}

class _DeleteStopScreenState extends State<DeleteStopScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Stop'),
      ),
      body: ListView.builder(
        itemCount: widget.stops.length,
        itemBuilder: (context, index) {
          String stop = widget.stops[index];
          return ListTile(
            title: Text(stop),
            trailing: IconButton(
              icon: Icon(Icons.delete),
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

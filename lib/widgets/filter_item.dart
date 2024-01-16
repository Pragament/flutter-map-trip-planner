import 'package:flutter/material.dart';

class FilterItem extends StatelessWidget {
  const FilterItem({required this.label, required this.onTapped, super.key});

  final String label;
  final void Function()? onTapped;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapped,
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
        padding: const EdgeInsets.all(6.0),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
        ),
      ),
    );
  }
}

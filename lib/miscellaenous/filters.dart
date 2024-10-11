// Future<void> _showFilterDialog() async {
//   String? result = await showDialog<String>(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Select Tag to Filter'),
//         content: DropdownButton<String>(
//           hint: const Text('select tags to filter the routes!'),
//           icon: const Icon(Icons.filter_alt),
//           value: selectedTag,
//           items: allTagsList.map((tag) {
//             return DropdownMenuItem<String>(
//               value: tag,
//               child: Text(tag),
//             );
//           }).toList(),
//           onChanged: (String? newValue) {
//             setState(() {
//               selectedTag = newValue;
//               _applyFilter();
//             });
//             Navigator.of(context).pop(newValue!);
//           },
//         ),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 selectedTag = null;
//                 _applyFilter();
//               });
//               Navigator.of(context).pop();
//             },
//             child: const Text('Clear Filter'),
//           ),
//         ],
//       );
//     },
//   );
//   print(result);
// }

// void _applyFilter() {
//   setState(() {
//     if (selectedTag != null) {
//       filteredRoutes = userRoutes1.where((route) {
//         String tagsString = route['tags'];
//         List<String> tags = tagsString.split(',');
//         return tags.contains(selectedTag);
//       }).toList();
//
//       filteredStops = userAddedStops.where((stop) {
//         String tagsString = stop['tags'];
//         List<String> tags = tagsString.split(',');
//         return tags.contains(selectedTag);
//       }).toList();
//     } else {
//       filteredRoutes.clear();
//       filteredStops.clear();
//     }
//   });
// }

// Widget _buildFilterButton() {
//   return ElevatedButton.icon(
//     icon: const Icon(
//       Icons.filter_alt,
//       color: Colors.white,
//     ),
//     onPressed: () {
//       _showFilterDialog();
//     },
//     label: Text(selectedTag != null ? 'Filter: $selectedTag' : 'Filter'),
//     style: const ButtonStyle(
//         backgroundColor: MaterialStatePropertyAll(Colors.greenAccent)),
//   );
// }
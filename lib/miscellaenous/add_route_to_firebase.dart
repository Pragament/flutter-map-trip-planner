import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addImportedRouteToFirebase(Map<String, dynamic> routeData) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    String userID = user.uid;

    // Step 1: Reference to the user's document
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userID);

    // Step 2: Fetch current user's route IDs
    // DocumentSnapshot userSnapshot = await userRef.get();
    // List<dynamic> routeIds = userSnapshot['routeIds'] ?? [];

    // Step 3: Check if the route already exists in 'routes' collection by name
    QuerySnapshot routeQuery = await FirebaseFirestore.instance
        .collection('routes')
        .where('routeName', isEqualTo: routeData['routeName'])
        .get();

    if (routeQuery.docs.isNotEmpty) {
      throw Exception('Route with the same name already exists');
    }

    // Step 4: Add the new route to the 'routes' collection
    DocumentReference routeRef =
        await FirebaseFirestore.instance.collection('routes').add(routeData);

    String newRouteId = routeRef.id;

    // Step 5: Update the user's document with the new route ID in 'routeIds'
    await userRef.update({
      'routeIds': FieldValue.arrayUnion([newRouteId]), // Add the new route ID
    });
  } else {
    throw Exception('User is not authenticated.');
  }
}

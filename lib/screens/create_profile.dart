import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileCreationScreen(this.phoneNumber, {super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _dobFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _dobFocusNode.addListener(() {
      if (_dobFocusNode.hasFocus) {
        _dobFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _dobController.dispose();
    _dobFocusNode.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    String name = _nameController.text; // Get the name from your text field
    String phoneNumber = widget.phoneNumber;
    String dob = _dobController.text;

    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Create a reference to the "users" collection
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    // Add a new document with a generated ID
    await users.doc(uid).set({
      'name': name,
      'phoneNumber': phoneNumber,
      'dateofbirth': dob,
      'routes': [],
      'useraddedstops': '',
    });
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('profile saved'),
          content: const Text('your profile was saved successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/allroutes');
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( foregroundColor:Colors.white, backgroundColor:Colors.green,
        title: const Text(
          'Create Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: widget.phoneNumber),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Choose from the calender 👉🏻',
                border: const OutlineInputBorder(),
                suffixIcon: GestureDetector(
                  onTap: () async {
                    DateTime currentTime = DateTime.now();
                    DateTime? selectedTime = await showDatePicker(
                      context: context,
                      initialDate: currentTime,
                      firstDate: DateTime(1900),
                      lastDate: currentTime,
                    );
                    if (selectedTime != null && selectedTime != currentTime) {
                      _dobController.text =
                          "${selectedTime.toLocal()}".split(' ')[0];
                    }
                  },
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

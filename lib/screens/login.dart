// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_trip_planner/screens/create_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  bool isPhoneNumberVerified = false;
  PhoneNumber number = PhoneNumber(isoCode: 'IN');

  String verificationId = '';

  Future<void> _verifyPhoneNumber() async {
    verificationCompleted(PhoneAuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);
      print('PHONE NUMBER VERIFIED');
      setState(() {
        isPhoneNumberVerified = true;
      });
    }

    verificationFailed(FirebaseAuthException authException) {
      print('Error: ${authException.message}');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error!'),
            content: Text('Error: ${authException.message}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }

    codeSent(String verificationId, int? resendToken) async {
      print('verificationId - $verificationId');
      this.verificationId = verificationId;
      setState(() {
        isPhoneNumberVerified = true;
      });
    }

    codeAutoRetrievalTimeout(String verificationId) {
      this.verificationId = verificationId;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: number.phoneNumber!,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> _signInWithPhoneNumber() async {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: _otpController.text,
    );

    print("CREDENTIALS VERIFIED");
    await _auth.signInWithCredential(credential);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('login_timestamp', DateTime.now().toString());
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot<Object?> snapshot =
    await users.where('phoneNumber', isEqualTo: number.phoneNumber).get();
    if (snapshot.docs.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/allroutes');
    } else {
      debugPrint("NEW USER");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationScreen(
            number.phoneNumber!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  setState(() {
                    this.number = number;
                  });
                },
                initialValue: number,
                inputDecoration: InputDecoration(
                  border: InputBorder.none,
                  enabled: isPhoneNumberVerified ? false : true,
                  labelText: "Enter mobile number here",
                  suffixIcon: isPhoneNumberVerified
                      ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                      : const Icon(
                    Icons.running_with_errors_outlined,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isPhoneNumberVerified ? null : _verifyPhoneNumber,
              child: const Text('Send Otp'),
            ),
            const SizedBox(height: 16),
            isPhoneNumberVerified
                ? Text(
              "Otp sent to ${number.phoneNumber}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )
                : const Text(
              'Click the above button to verify phone number and'
                  ' request an OTP!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signInWithPhoneNumber,
              child: const Text('Sign In with OTP'),
            ),
            const Spacer(), // Pushes the next button to the bottom
            SizedBox(
              width: double.infinity, // Set the button width to take up the full screen width
              child: ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('skip_login', true); // Save the skip login state
                  Navigator.pushReplacementNamed(context, '/allroutes');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Same as "Send Otp" button
                  foregroundColor: Colors.white, // Text color (same as "Send Otp" button)
                ),
                child: const Text(
                  'Skip Login',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

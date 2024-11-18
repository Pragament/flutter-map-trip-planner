import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class UserInfoProvider extends ChangeNotifier {
  String userName = '';
  String dateOfBirth = '';
  String phoneNumber = '';
  bool isUserAdmin = false;

  void assignUserInfo(
      {required String userName,
      required String dateOfBirth,
      required String phoneNumber,
      required bool isUserAdmin}) {
    this.userName = userName;
    this.dateOfBirth = dateOfBirth;
    this.phoneNumber = phoneNumber;
    this.isUserAdmin = isUserAdmin;
    notifyListeners();
  }
}

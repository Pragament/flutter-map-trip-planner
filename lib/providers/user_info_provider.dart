import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class UserInfoProvider extends ChangeNotifier {
  String userName = '';
  String dateOfBirth = '';
  String phoneNumber = '';
  User? _user;

  User? get user => _user;

  void assignUserInfo(
      {required String userName,
      required String dateOfBirth,
      required String phoneNumber}) {
    this.userName = userName;
    this.dateOfBirth = dateOfBirth;
    this.phoneNumber = phoneNumber;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Logout user
  void logout() {
    _user = null;
    notifyListeners();
  }
}

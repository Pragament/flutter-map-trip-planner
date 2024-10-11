import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class UserInfoProvider extends ChangeNotifier
{
  String userName = '';
  String dateOfBirth = '';
  String phoneNumber = '';

  void assignUserInfo({required String userName,required String dateOfBirth, required String phoneNumber})
  {
    this.userName = userName;
    this.dateOfBirth = dateOfBirth;
    this.phoneNumber = phoneNumber;
    notifyListeners();
  }
}
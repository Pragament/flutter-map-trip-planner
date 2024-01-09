
import 'package:flutter/cupertino.dart';

class LoadingProvider extends ChangeNotifier
{
  bool locationLoading = false;

  void changeLocationLoadingState(bool state)
  {
    locationLoading = state;
    notifyListeners();
  }

}
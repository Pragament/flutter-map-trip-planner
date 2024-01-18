import 'package:flutter/cupertino.dart';

class LoadingProvider extends ChangeNotifier
{
  bool locationLoading = true;

  void changeLocationLoadingState(bool state)
  {
    locationLoading = state;
    notifyListeners();
  }

  bool addStopUpdateLocation = false;

  void changeAddStopsUpdateLocationState(bool state)
  {
    addStopUpdateLocation = state;
    notifyListeners();
  }

  bool allRoutesUpdateLocation = false;

  void changAllRoutesUpdateLocationState(bool state)
  {
    allRoutesUpdateLocation = state;
    notifyListeners();
  }

  bool routeCreationUpdateLocation = false;

  void changeRouteCreationUpdateLocationState(bool state)
  {
    routeCreationUpdateLocation = state;
    notifyListeners();
  }

  bool editRouteLoading = false;

  void changeEditRouteLoadingState(bool state)
  {
    editRouteLoading = state;
    notifyListeners();
  }

  bool copyRouteLoading = false;

  void changeCopyRouteLoadingState(bool state)
  {
    copyRouteLoading = state;
    notifyListeners();
  }

  bool allRoutesScreenFilter = false;

  void changeAllRoutesScreenToggleState(bool state)
  {
    allRoutesScreenFilter = state;
    notifyListeners();
  }
}
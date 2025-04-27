
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:on_demant_home_service_app/model/location_model.dart';



class LocationController with ChangeNotifier {
  Locationmoadel? startLocationModel;
  Locationmoadel? endLocationModel;

  List<Result> startLocationsList = [];
  List<Result> endLocationsList = [];
  
  bool isStartLoading = false;
  bool isEndLoading = false;

  get locationslist => null;

  Future<void> onStartLocationSearch(String keyword) async {
    isStartLoading = true;
    notifyListeners();
    var url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?address=$keyword&key=AIzaSyCX6jheIEuMGvB_dG17OVw81bX0KWSf__k");
    var response = await http.get(url);

    if (response.statusCode == 200) {
      startLocationModel = locationmoadelFromJson(response.body);
      startLocationsList = startLocationModel?.results ?? [];
    }

    isStartLoading = false;
    notifyListeners();
  }

  Future<void> onEndLocationSearch(String keyword) async {
    isEndLoading = true;
    notifyListeners();
    var url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?address=$keyword&key=AIzaSyCX6jheIEuMGvB_dG17OVw81bX0KWSf__k");
    var response = await http.get(url);

    if (response.statusCode == 200) {
      endLocationModel = locationmoadelFromJson(response.body);
      endLocationsList = endLocationModel?.results ?? [];
    }

    isEndLoading = false;
    notifyListeners();
  }

  void clearStartLocations() {
    startLocationsList.clear();
    notifyListeners();
  }

  void clearEndLocations() {
    endLocationsList.clear();
    notifyListeners();
  }

  void onLocationSearch(String text) {}

  void clearLocationsList() {}
}

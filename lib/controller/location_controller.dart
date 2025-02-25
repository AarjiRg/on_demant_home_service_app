

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:on_demant_home_service_app/model/location_model.dart';

class LocationController with ChangeNotifier {
  Locationmoadel? locationresmodel;
  List<Result> locationslist = [];
  bool isloading = false;



  Future<void> onLocationSearch(String keyword) async {
    isloading = true;
    notifyListeners();
    var url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?address=$keyword&key=AIzaSyCX6jheIEuMGvB_dG17OVw81bX0KWSf__k");
    var locationresponse = await http.get(url);
    
    if (locationresponse.statusCode == 200) {
      locationresmodel = locationmoadelFromJson(locationresponse.body);
      if (locationresmodel != null) {
        locationslist = locationresmodel!.results ?? [];
      }
    }
    
    isloading = false;
    notifyListeners();
  }

 
  void clearLocationsList() {
    locationslist.clear();
    notifyListeners();
  }
}

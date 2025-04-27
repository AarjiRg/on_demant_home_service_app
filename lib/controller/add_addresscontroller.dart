
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AddAddresscontroller with ChangeNotifier{
     final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
  Future<void > addAddress(
     {
  required String fullName,
  required String housenumber,
  required String landmark,
  required String pincode,
  required String location,
  required String phnumber,
  required String roadname,
  required BuildContext context,
  
 }
  )async {
try {
  User? user = auth.currentUser;
  if(user == null){
    throw Exception("User not logged in.");
  }
   String addressid = firestore.collection('users').doc().id;

   Map<String, dynamic> addressdata = {
        'addressid': addressid,
        'fullName': fullName,
        'housenumber': housenumber,
        'landmark': landmark,
        'pincode': pincode,
        'location': phnumber,
        'roadname': roadname,
        'location': location,
        'savedon': FieldValue.serverTimestamp(),
      };
       await firestore
          .collection('users')
          .doc(user.uid)
          .collection('myaddress')
          .doc(addressid)
          .set(addressdata);
 ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('address added')),
      );
     
if (firestore.databaseId!=null) {
 
  
}
      notifyListeners();
} catch (e) {
  print("Error submitting blood request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit blood request.')),
      );
}
  }
}
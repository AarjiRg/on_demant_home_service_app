
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/view/bottam_nav_bar.dart';

class LoginScreenController with ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? userData; 
  Future<void> onLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

    
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        String uid = credential.user!.uid;

       
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>BottomNavScreen() ,));
        
        } else {
          print("User data not found in Firestore.");
        }
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

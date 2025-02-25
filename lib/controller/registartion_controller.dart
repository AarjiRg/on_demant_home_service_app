
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:on_demant_home_service_app/view/login_screen.dart';

class RegistrationController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> onRegistration({
    required String emailAddress,
    required String password,
    required String name,
    required String phone,
    required String location,
    required BuildContext context, required fullName
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'lastname':fullName,
          'phone': phone,
          'location': location,
          'uid': credential.user!.uid,
          'registeredAt': FieldValue.serverTimestamp(),
        });
      }
      if (credential.user != null)  {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }
}







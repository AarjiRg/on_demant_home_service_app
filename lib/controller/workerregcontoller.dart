import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/view/workerlogin.dart';

class WorkerRegistrationController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> onRegistration({
    required String emailAddress,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String location,
    required List<String> services,
    required String experience,
    required String idNumber,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      if (credential.user != null) {
        final userData = {
          'firstName': firstName,
          'lastName': lastName,
          'email': emailAddress,
          'phone': phone,
          'location': location,
          'uid': credential.user!.uid,
          'accountStatus': 'pending', 
          'registeredAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'role': 'worker',
        };

        final workerSpecificData = {
          ...userData,
          'services': services,
          'experience': experience,
          'idNumber': idNumber,
          'rating': 0.0,
          'completedJobs': 0,
        };

        final workerProfileData = {
          'firstName': firstName,
          'lastName': lastName,
          'services': services,
          'experience': experience,
          'location': location,
          'rating': 0.0,
          'completedJobs': 0,
          'profileImage': '',
          'hourlyRate': null,
          'about': '',
          'isAvailable': true,
          'role': 'worker',
        };

  
        await _firestore.collection('users').doc(credential.user!.uid).set(userData);

  
        await _firestore.collection('workers').doc(credential.user!.uid).set(workerSpecificData);

       
        await _firestore.collection('worker_profiles').doc(credential.user!.uid).set(workerProfileData);
      }

      if (credential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerLoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed. Please try again.';
      
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWorkerProfile({
    required String uid,
    required Map<String, dynamic> updateData,
  }) async {
    try {
   
      await _firestore.collection('users').doc(uid).update(updateData);
      await _firestore.collection('workers').doc(uid).update(updateData);
      await _firestore.collection('worker_profiles').doc(uid).update(updateData);
    } catch (e) {
      print('Error updating worker profile: $e');
      rethrow;
    }
  }

  Future<void> updateAvailability(String uid, bool isAvailable) async {
    try {
      final updateData = {
        'isAvailable': isAvailable,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(uid).update(updateData);
      await _firestore.collection('workers').doc(uid).update(updateData);
      await _firestore.collection('worker_profiles').doc(uid).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      print('Error updating availability: $e');
      rethrow;
    }
  }
}
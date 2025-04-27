import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AddWorkersController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  Future<void> onAddingNewWorker({
    required String workerName,
    required String description,
    required String hourlyPrice,
    required String fullDayPrice,
    required String category,
    required String location,
    required String imageUrl,
    required String availability,
    required String skills,
    required String notes,
    required String phnumber,
    required String requiredSkills,
    required BuildContext context,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      print("User is logged in: ${user.uid}");

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists || !userDoc.data().toString().contains('name')) {
        throw Exception("User details not found.");
      }

      print("User details found: ${userDoc.data()}");

      String username = userDoc.get('name');
      String workerId = _firestore.collection('workers').doc().id;

      print("Generated worker ID: $workerId");

      Map<String, dynamic> newWorkerData = {
        'workerName': workerName,
        'workerId': workerId,
        'description': description,
        'hourlyPrice': hourlyPrice,
        'fullDayPrice': fullDayPrice,
        'category': category,
        'location': location,
        'image': imageUrl,
        'availability': availability,
        'skills': skills,
        'notes': notes,
        'requiredSkills': requiredSkills,
        'addedByUserId': user.uid,
        'addedByUsername': username,
        'phnumber':phnumber,
        'addedAt': FieldValue.serverTimestamp(),
      };

      print("Worker data to be added: $newWorkerData");

      await _firestore.collection('workers').doc(workerId).set(newWorkerData);
      print("Worker added to Firestore");

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('myWorkers')
          .doc(workerId)
          .set(newWorkerData);
      print("Worker added to user's myWorkers collection");

      await _firestore.collection('users').doc(user.uid).update({
        'isWorker': true,
      });
      print("User profile updated to mark as a worker");

      notifyListeners();
    } catch (e) {
      print("Error adding worker: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add worker: $e')),
      );
    }
  }

  Future<String?> uploadImg(File imageFile) async {
    isLoading = true;
    notifyListeners();

    final FirebaseStorage storage = FirebaseStorage.instance;
    Reference folder = storage.ref().child("worker_images");
    Reference imageRef =
        folder.child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    try {
      await imageRef.putFile(imageFile);
      String uploadImgUrl = await imageRef.getDownloadURL();
      print("Uploaded Worker Image URL: $uploadImgUrl");

      isLoading = false;
      notifyListeners();
      return uploadImgUrl;
    } catch (e) {
      print("Upload Error: $e");
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
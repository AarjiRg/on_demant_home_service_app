import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ProfileScreenController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  File? _imageFile;

  ProfileScreenController() {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          userData = doc.data() as Map<String, dynamic>;
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      notifyListeners();
      await uploadImage();
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    try {
      User? user = _auth.currentUser;
      if (user != null) {
      
        final ref = _storage.ref().child('user_profile_images/${user.uid}.jpg');
        await ref.putFile(_imageFile!);

    
        final imageUrl = await ref.getDownloadURL();

        
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });

       
        userData?['profileImageUrl'] = imageUrl;
        notifyListeners();
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? bio,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update Firestore document
        Map<String, dynamic> updateData = {};
        if (name != null) updateData['name'] = name;
        if (email != null) updateData['email'] = email;
        if (bio != null) updateData['bio'] = bio;

        await _firestore.collection('users').doc(user.uid).update(updateData);

        // Update local user data
        if (name != null) userData?['name'] = name;
        if (email != null) userData?['email'] = email;
        if (bio != null) userData?['bio'] = bio;

        notifyListeners();
      }
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  void logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }
}
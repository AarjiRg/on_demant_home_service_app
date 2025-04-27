import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/view/admin_view/AdminHomeScreen.dart';
import 'package:on_demant_home_service_app/view/bottam_nav_bar.dart';

class LoginScreenController with ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? userData;
  String? errorMessage;

  Future<void> onLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        String uid = credential.user!.uid;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          final role = userData?['role']?.toString().toLowerCase() ?? 'user';

          // Navigate based on role without restarting the app
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => role == 'admin' 
                  ? const AdminHomeScreen() 
                  : const BottomNavScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        } else {
          errorMessage = "User data not found in Firestore.";
          _showErrorDialog(context, errorMessage!);
        }
      }
    } on FirebaseAuthException catch (e) {
      errorMessage = _getFirebaseAuthErrorMessage(e);
      _showErrorDialog(context, errorMessage!);
    } catch (e) {
      errorMessage = "An unexpected error occurred. Please try again.";
      _showErrorDialog(context, errorMessage!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  // Check if user is already logged in when app starts
  Future<void> checkCurrentUser(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          final role = userData?['role']?.toString().toLowerCase() ?? 'user';

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => role == 'admin' 
                  ? const AdminHomeScreen() 
                  : const BottomNavScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      errorMessage = "Error checking user status.";
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
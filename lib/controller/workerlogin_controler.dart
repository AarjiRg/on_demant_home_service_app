import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/view/worker_home_screen.dart';

class WorkerLoginScreenController with ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? workerData;

  Future<void> onWorkerLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      debugPrint('🚀 Starting worker login process');

      debugPrint('🔑 Attempting authentication...');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        debugPrint('❌ Authentication failed - no user returned');
        throw Exception('Authentication failed');
      }

      final uid = credential.user!.uid;
      debugPrint('🆔 Authenticated user UID: $uid');


      debugPrint('📂 Checking user role in users collection...');
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ No user document found');
        await FirebaseAuth.instance.signOut();
        throw Exception('Account not registered');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      debugPrint('👤 User data loaded: ${userData.keys.join(', ')}');


      if (userData['role']?.toString().toLowerCase() != 'worker') {
        debugPrint('❌ Invalid role in users collection: ${userData['role']}');
        await FirebaseAuth.instance.signOut();
        throw Exception('Invalid account type - not a worker');
      }

 
      debugPrint('📂 Fetching worker data from workers collection...');
      final workerDoc = await FirebaseFirestore.instance
          .collection("workers")
          .doc(uid)
          .get();

      if (workerDoc.exists) {
        workerData = workerDoc.data() as Map<String, dynamic>;
        debugPrint('👷 Worker data loaded: ${workerData?.keys.join(', ')}');
      }

      debugPrint('👉 Navigating to WorkerHomeScreen');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => WorkerHomeScreen()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Auth error: ${e.code} - ${e.message}');
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
      debugPrint('🏁 Login process completed');
    }
  }


  onLogin({required String email, required String password, required BuildContext context}) {}
}
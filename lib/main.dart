import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/add_addresscontroller.dart';
import 'package:on_demant_home_service_app/controller/add_wrokers_controller.dart';
import 'package:on_demant_home_service_app/controller/location_controller.dart';
import 'package:on_demant_home_service_app/controller/login_controller.dart';
import 'package:on_demant_home_service_app/controller/profile_screen_controller.dart';
import 'package:on_demant_home_service_app/controller/registartion_controller.dart';
import 'package:on_demant_home_service_app/controller/workerlogin_controler.dart';
import 'package:on_demant_home_service_app/firebase_options.dart';
import 'package:on_demant_home_service_app/view/WorkerSplashScreen.dart';
import 'package:on_demant_home_service_app/view/admin_view/AdminHomeScreen.dart';
import 'package:on_demant_home_service_app/view/bottam_nav_bar.dart';
import 'package:on_demant_home_service_app/view/homesplashscreen.dart';
import 'package:on_demant_home_service_app/view/splash_screen.dart';
import 'package:on_demant_home_service_app/view/startup_screen.dart';
import 'package:on_demant_home_service_app/controller/workerregcontoller.dart';
import 'package:on_demant_home_service_app/view/worker_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => LoginScreenController()),
      ChangeNotifierProvider(create: (context) => LocationController()),
      ChangeNotifierProvider(create: (context) => RegistrationController()),
      ChangeNotifierProvider(create: (context) => AddWorkersController()),
      ChangeNotifierProvider(create: (context) => ProfileScreenController()),
      ChangeNotifierProvider(create: (context) => AddAddresscontroller()),
      ChangeNotifierProvider(create: (context) => WorkerLoginScreenController()),
      ChangeNotifierProvider(create: (context) => WorkerRegistrationController()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'On Demand Services',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget _getScreenBasedOnRole(String role) {
    if (role == 'admin') {
      return const AdminHomeScreen();
    } else if (role == 'worker') {
      return const WorkerSplashScreen();
    }
    return const HomeSplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
       if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const WelcomeScreen();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const WelcomeScreen();
            }
            final userData = roleSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role']?.toString().toLowerCase() ?? 'user';
            return _getScreenBasedOnRole(role);
          },
        );
      },
    );
  }
}
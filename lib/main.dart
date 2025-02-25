

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/location_controller.dart';
import 'package:on_demant_home_service_app/controller/login_controller.dart';
import 'package:on_demant_home_service_app/controller/registartion_controller.dart';
import 'package:on_demant_home_service_app/firebase_options.dart';
import 'package:on_demant_home_service_app/view/bottam_nav_bar.dart';
import 'package:on_demant_home_service_app/view/splash_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
 options: DefaultFirebaseOptions.currentPlatform,
);
runApp(MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => LoginScreenController(),),
      ChangeNotifierProvider(create: (context) => LocationController(),),
        ChangeNotifierProvider(create: (context) => RegistrationController(),),

        


  ],
  child: MyApp()));
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:StreamBuilder(   
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return BottomNavScreen();
          }else{  
            return IntroScreen();
          }
        },
      )
    );
  }
}
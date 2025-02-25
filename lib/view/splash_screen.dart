import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:on_demant_home_service_app/view/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  String _displayedText = ""; 
  final String _fullText = "HomeAssist"; 
  int _currentIndex = 0; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();

   
    _startTypingAnimation();

   
    Future.delayed(const Duration(seconds: 5)).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    });
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel(); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.asset("assets/aminations/Animation - 1740447259894.json"),
            ), 
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Text(
                _displayedText,
                style: GoogleFonts.lobsterTwo(color: Colors.black, fontSize: 24,fontWeight: FontWeight.w800,shadows: [Shadow(color: Colors.black,blurRadius: 50,offset: Offset(0, 10))]),
              ),
            ),
          ],
        ), 
      ),
    );
  }
}
 
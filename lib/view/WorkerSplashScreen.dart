import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:on_demant_home_service_app/view/worker_home_screen.dart';

class WorkerSplashScreen extends StatefulWidget {
  const WorkerSplashScreen({super.key});

  @override
  State<WorkerSplashScreen> createState() => _WorkerSplashScreenState();
}

class _WorkerSplashScreenState extends State<WorkerSplashScreen> {
  String _displayedText = ""; 
  final String _fullText = "HomeAssist Pro"; 
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
          builder: (context) => WorkerHomeScreen(),
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
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Text(
                _displayedText,
                style: GoogleFonts.lobsterTwo(
                  color: Colors.blue[800], 
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5)
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Professional Services Platform",
              style: GoogleFonts.roboto(
                color: Colors.grey[700],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ), 
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/view/bookingscreen.dart';
import 'package:on_demant_home_service_app/view/home_screen.dart';
import 'package:on_demant_home_service_app/view/profile_screen.dart';
import 'package:on_demant_home_service_app/view/search_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int sindex = 0;
  final List<Widget> screens = [
    ServiceBookingScreen(),
    WorkerSearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[sindex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: sindex,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          setState(() {
            sindex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
         
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "proflie",
          ),
        ],
      ),
    );
  }
}

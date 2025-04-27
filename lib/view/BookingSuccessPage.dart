import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/bottam_nav_bar.dart';
import 'package:on_demant_home_service_app/view/home_screen.dart';

class BookingSuccessPage extends StatelessWidget {
  final String bookingId;
  final String workerName;
  final String bookingDate;
  final String bookingTime;
  final String address;
  final String price;

  const BookingSuccessPage({
    required this.bookingId,
    required this.workerName,
    required this.bookingDate,
    required this.bookingTime,
    required this.address,
    required this.price,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Confirmed"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              "Booking Confirmed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Your booking has been placed successfully",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            _buildDetailCard(),
            SizedBox(height: 30),
            Text(
              "Booking ID: $bookingId",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>BottomNavScreen(),));
              },
              child: Text("Back to Home"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow("Worker:", workerName),
            Divider(),
            _buildDetailRow("Service Date:", bookingDate),
            Divider(),
            _buildDetailRow("Service Time:", bookingTime),
            Divider(),
            _buildDetailRow("Address:", address),
            Divider(),
            _buildDetailRow("Amount:", "₹$price"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
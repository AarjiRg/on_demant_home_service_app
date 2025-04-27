import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/BookingSuccessPage.dart';
import 'package:on_demant_home_service_app/view/admin_view/addnew_addresspage.dart';

class BookWorkerScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String category;
  final String location;
  final String price;
  final String phoneNumber;
  final String workerImage;
  final List<String> workImages;

  const BookWorkerScreen({
    required this.workerId,
    required this.workerName,
    required this.category,
    required this.location,
    required this.price,
    required this.phoneNumber,
    required this.workerImage,
    required this.workImages,
    super.key,
  });

  @override
  _BookWorkerScreenState createState() => _BookWorkerScreenState();
}

class _BookWorkerScreenState extends State<BookWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethod;
  String? _selectedAddress;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _additionalNotes = '';
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  
Future<void> _confirmBooking() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedPaymentMethod == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select a payment method")),
    );
    return;
  }

  if (_selectedAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please add an address")),
    );
    return;
  }

  if (_selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select date and time")),
    );
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');


    final bookingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );


    final bookingData = {
      'workerId': widget.workerId,
      'workerName': widget.workerName,
      'workerImage': widget.workerImage,
      'workerPhone': widget.phoneNumber,
      'category': widget.category,
      'price': widget.price,
      'customerId': user.uid,
      'customerName': user.displayName ?? 'Customer',
      'customerPhone': user.phoneNumber ?? 'Not provided',
      'customerEmail': user.email,
      'address': _selectedAddress,
      'paymentMethod': _selectedPaymentMethod,
      'bookingDateTime': bookingDateTime,
      'status': 'pending',
      'rejectionReason': '',
      'additionalNotes': _additionalNotes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };


    final db = FirebaseFirestore.instance;
    final bookingRef = await db.collection('bookings').add(bookingData);


    await db.collection('users').doc(user.uid).collection('myBookings').doc(bookingRef.id).set({
      ...bookingData,
      'bookingId': bookingRef.id,
    });


    await db.collection('workers').doc(widget.workerId).collection('myBookedWorks').doc(bookingRef.id).set({
      ...bookingData,
      'bookingId': bookingRef.id,
    });


    await _sendNotificationToWorker(
      workerId: widget.workerId,
      bookingId: bookingRef.id,
      customerName: user.displayName ?? 'A customer',
    );


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSuccessPage(
          bookingId: bookingRef.id,
          workerName: widget.workerName,
          bookingDate: DateFormat('MMM dd, yyyy').format(bookingDateTime),
          bookingTime: DateFormat('hh:mm a').format(bookingDateTime),
          address: _selectedAddress!,
          price: widget.price,
        ),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking failed: ${e.toString()}")),
    );
  }
}

Future<void> _sendNotificationToWorker({
  required String workerId,
  required String bookingId,
  required String customerName,
}) async {
  final db = FirebaseFirestore.instance;
  
  await db.collection('workers').doc(workerId).collection('notifications').add({
    'title': 'New Booking Request',
    'message': '$customerName has requested your service',
    'type': 'new_booking',
    'bookingId': bookingId,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

  void _navigateToAddAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
        _addressController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book ${widget.workerName}"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          
              _buildWorkerDetailsCard(),

              SizedBox(height: 20),

          
              if (widget.workImages.isNotEmpty) ...[
                Text("Work Samples:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.workImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.workImages[index],
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],

              Text("🏠 Service Address:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _selectedAddress == null
                  ? _buildPrimaryButton("ADD ADDRESS", _navigateToAddAddressScreen)
                  : _buildCard([
                      ListTile(
                        leading: Icon(Icons.location_on, color: Colors.blueAccent),
                        title: Text(_selectedAddress!, style: TextStyle(fontSize: 16)),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: _navigateToAddAddressScreen,
                        ),
                      )
                    ]),

              SizedBox(height: 20),

    
              Text("📅 Select Date & Time:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeButton(
                      _selectedDate == null 
                          ? "Select Date" 
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      () => _selectDate(context),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildDateTimeButton(
                      _selectedTime == null 
                          ? "Select Time" 
                          : _selectedTime!.format(context),
                      () => _selectTime(context),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Text("📝 Additional Notes:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Any special instructions or requirements...",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _additionalNotes = value,
              ),

              SizedBox(height: 20),

 
              Text("💳 Select Payment Method:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _paymentOption("Cash on Delivery", Icons.money),
              _paymentOption("UPI", Icons.payment),
              _paymentOption("Debit/Credit Card", Icons.credit_card),

              SizedBox(height: 30),

         
              _buildPrimaryButton("CONFIRM BOOKING", _confirmBooking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(widget.workerImage),
              onBackgroundImageError: (_, __) {},
              child: widget.workerImage.isEmpty ? Icon(Icons.person, size: 40) : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.workerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(widget.category, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text("₹${widget.price}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(text, style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildDateTimeButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.blueAccent),
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _paymentOption(String method, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(method),
          ],
        ),
        activeColor: Colors.blueAccent,
      ),
    );
  }
}

class AddAddressScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Address"), 
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter complete address with landmarks",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  Navigator.pop(context, _controller.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter an address")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("SAVE ADDRESS", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
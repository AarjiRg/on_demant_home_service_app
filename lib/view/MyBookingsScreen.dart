import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(
                "Not Authenticated",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              Text(
                "Please login to view your bookings",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('myBookings')
            .orderBy('bookingDateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Error loading bookings",
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No Bookings Yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    "Book a service to see it here",
                    style: TextStyle(color: Colors.grey),)
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var bookingData = booking.data() as Map<String, dynamic>;
              return _buildBookingCard(bookingData, booking.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> bookingData, String bookingId) {
    try {
      final bookingDateTime = _parseTimestamp(bookingData['bookingDateTime']);
      if (bookingDateTime == null) {
        return _buildErrorCard("Invalid booking date/time");
      }
      
      final now = DateTime.now();
      final timeDifference = bookingDateTime.difference(now);
      final canCancel = timeDifference.inHours > 1;
      final cancellationReason = _getCancellationReason(timeDifference);
      
      final status = bookingData['status']?.toString().toLowerCase() ?? 'pending';
      final isCompleted = status == 'completed';
      final isCancelled = status == 'cancelled';
      final isRejected = status == 'rejected';
      final isPending = status == 'pending';
      final isAccepted = status == 'accepted';

      final workerName = bookingData['workerName']?.toString() ?? 'Unknown Worker';
      final category = bookingData['category']?.toString() ?? 'Service';
      final price = bookingData['price']?.toString() ?? '0';
      final paymentMethod = bookingData['paymentMethod']?.toString() ?? 'Cash';
      final address = bookingData['address']?.toString();
      final additionalNotes = bookingData['additionalNotes']?.toString();
      final rejectionReason = bookingData['rejectionReason']?.toString();
      final workerImage = bookingData['workerImage']?.toString();
      final workerPhone = bookingData['workerPhone']?.toString();
      final workerId = bookingData['workerId']?.toString();

      return Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: workerImage != null && workerImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: workerImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.person),
                            ),
                          )
                        : Icon(Icons.person, size: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAccepted || isPending || isCompleted || isCancelled || isRejected)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Booking Date & Time",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _dateFormat.format(bookingDateTime),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _timeFormat.format(bookingDateTime),
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Price",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "₹$price",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        paymentMethod,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (address != null && address.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Address",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      address,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              if (additionalNotes != null && additionalNotes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      "Additional Notes",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      additionalNotes,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              if (isRejected && rejectionReason != null && rejectionReason.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      "Rejection Reason",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      rejectionReason,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              SizedBox(height: 12),
              if (isPending || isAccepted)
                Row(
                  children: [
                    if (canCancel && (isPending || isAccepted))
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showCancelDialog(
                            bookingId, 
                            bookingData,
                            workerId,
                            paymentMethod.toLowerCase().contains('cash'),
                          ),
                          child: Text(
                            "Cancel Booking",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    if (!canCancel && (isPending || isAccepted))
                      Expanded(
                        child: Tooltip(
                          message: cancellationReason,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: null,
                            child: Text(
                              "Cancel Not Available",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(width: 12),
                    if (workerPhone != null && workerPhone.isNotEmpty)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPending 
                                ? Colors.blue.shade800 
                                : Colors.green.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _contactWorker(workerPhone),
                          child: Text(
                            "Contact Worker",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              if (isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: () => _rateWorker(bookingData),
                  child: Text(
                    "Rate Service",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (isCancelled)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: () => _bookAgain(bookingData),
                  child: Text(
                    "Book Again",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorCard("Error displaying booking: ${e.toString()}");
    }
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(height: 8),
            Text(
              "Error displaying booking",
              style: TextStyle(color: Colors.red),
            ),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getCancellationReason(Duration timeDifference) {
    if (timeDifference.isNegative) {
      return "Booking time has already passed";
    }
    if (timeDifference.inHours <= 1) {
      return "Cancellation is only allowed more than 1 hour before the booking time";
    }
    return "Cancellation available";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showCancelDialog(
    String bookingId, 
    Map<String, dynamic> bookingData,
    String? workerId,
    bool isCashOnDelivery,
  ) async {
    final now = DateTime.now();
    final bookingDateTime = _parseTimestamp(bookingData['bookingDateTime']);
    if (bookingDateTime == null) return;

    final timeDifference = bookingDateTime.difference(now);
    final canCancel = timeDifference.inHours > 1;

    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getCancellationReason(timeDifference)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel Booking"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Are you sure you want to cancel this booking?"),
              SizedBox(height: 8),
              if (!isCashOnDelivery)
                Text(
                  "Your payment will be refunded within 3-5 business days",
                  style: TextStyle(color: Colors.green),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cancelBooking(
                  bookingId, 
                  workerId,
                  isCashOnDelivery,
                );
              },
              child: Text(
                "Yes, Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking(
    String bookingId, 
    String? workerId,
    bool isCashOnDelivery,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Processing cancellation..."),
                if (!isCashOnDelivery) SizedBox(height: 8),
                if (!isCashOnDelivery)
                  Text(
                    "Processing refund...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      );

      // Update user's booking status
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('myBookings')
          .doc(bookingId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Remove from worker's myBookedWorks collection if workerId exists
      if (workerId != null && workerId.isNotEmpty) {
        await _firestore
            .collection('workers')
            .doc(workerId)
            .collection('myBookedWorks')
            .doc(bookingId)
            .delete();
      }

      // Update main bookings collection
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (!isCashOnDelivery) {
        await Future.delayed(Duration(seconds: 2));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refund initiated. It will reflect in 3-5 business days'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _contactWorker(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Worker phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rateWorker(Map<String, dynamic> bookingData) async {
    double rating = 0;
    TextEditingController reviewController = TextEditingController();
    final workerId = bookingData['workerId']?.toString();
    final workerName = bookingData['workerName']?.toString() ?? 'the worker';
    final bookingId = bookingData['bookingId']?.toString();

    if (workerId == null || workerId.isEmpty || bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to rate this booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Rate $workerName"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("How would you rate your experience?"),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      labelText: 'Your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  onPressed: () async {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a rating'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    await _submitRating(
                      workerId,
                      bookingId,
                      rating,
                      reviewController.text,
                      workerName,
                    );
                  },
                  child: Text(
                    "Submit Rating",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(
    String workerId,
    String bookingId,
    double rating,
    String review,
    String workerName,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Submitting your rating..."),
              ],
            ),
          );
        },
      );

      // Add rating to worker's ratings collection
      await _firestore
          .collection('workers')
          .doc(workerId)
          .collection('ratings')
          .add({
            'userId': user.uid,
            'userName': user.displayName ?? 'Anonymous',
            'bookingId': bookingId,
            'rating': rating,
            'review': review.isNotEmpty ? review : null,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update worker's average rating
      await _updateWorkerAverageRating(workerId);

      // Mark booking as rated
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('myBookings')
          .doc(bookingId)
          .update({
            'rated': true,
          });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for rating $workerName!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateWorkerAverageRating(String workerId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('workers')
          .doc(workerId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int ratingCount = 0;

      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] as num).toDouble();
        ratingCount++;
      }

      final averageRating = totalRating / ratingCount;

      await _firestore
          .collection('workers')
          .doc(workerId)
          .update({
            'rating': averageRating,
            'ratingCount': ratingCount,
          });
    } catch (e) {
      print('Error updating worker average rating: $e');
    }
  }

  Future<void> _bookAgain(Map<String, dynamic> bookingData) async {
    final workerId = bookingData['workerId']?.toString();
    if (workerId == null || workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to find worker details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to worker details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailsScreen(workerId: workerId),
      ),
    );
  }
}

class WorkerDetailsScreen extends StatelessWidget {
  final String workerId;

  const WorkerDetailsScreen({required this.workerId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Details'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('workers')
            .doc(workerId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Worker not found'));
          }

          final workerData = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = workerData['fullName'] ?? 'Unknown Worker';
          final serviceCategory = workerData['serviceCategory'] ?? 'Service';
          final rating = workerData['rating']?.toStringAsFixed(1) ?? '0.0';
          final yearsExperience = workerData['yearsExperience'] ?? '0';
          final hourlyRate = workerData['hourlyRate'] ?? '0';
          final aboutMe = workerData['aboutMe'] ?? 'No description available';
          final profileImage = workerData['profileImage'] as String?;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    serviceCategory,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Rating',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              rating,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Experience',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '$yearsExperience years',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Hourly Rate',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '₹$hourlyRate',
                    
                    
                    
                    
                    
                    
                    
                    
                    
                                style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(aboutMe),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
               
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking functionality would be implemented here'),
                      ),
                    );
                  },
                  child: Text(
                    'Book This Worker',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
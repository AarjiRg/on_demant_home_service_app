import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorkerBookingsPage extends StatelessWidget {
  const WorkerBookingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                'Please login as a worker',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.grey.shade100],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workers')
              .doc(workerId)
              .collection('myBookedWorks')
              .orderBy('bookingDateTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 20),
                    Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = snapshot.data!.docs[index];
                final data = booking.data() as Map<String, dynamic>;
                final bookingDate = _parseTimestamp(data['bookingDateTime']);
                
                return _buildBookingCard(
                  context,
                  bookingData: data,
                  bookingId: booking.id,
                  customerName: data['customerName']?.toString() ?? 'Unknown Customer',
                  category: data['category']?.toString() ?? 'Unknown Service',
                  date: bookingDate != null 
                      ? DateFormat('MMM dd, yyyy').format(bookingDate) 
                      : 'Date not specified',
                  time: bookingDate != null 
                      ? DateFormat('hh:mm a').format(bookingDate) 
                      : 'Time not specified',
                  status: data['status']?.toString() ?? 'pending',
                  onAccept: () => _updateBookingStatus(
                    context,
                    bookingId: booking.id,
                    workerId: workerId,
                    customerId: data['customerId']?.toString(),
                    status: 'accepted',
                  ),
                  onReject: (reason) => _updateBookingStatus(
                    context,
                    bookingId: booking.id,
                    workerId: workerId,
                    customerId: data['customerId']?.toString(),
                    status: 'rejected',
                    rejectionReason: reason,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context, {
    required Map<String, dynamic> bookingData,
    required String bookingId,
    required String customerName,
    required String category,
    required String date,
    required String time,
    required String status,
    required VoidCallback onAccept,
    required Function(String) onReject,
  }) {
    Color statusColor = _getStatusColor(status);
    Color statusBgColor = statusColor.withOpacity(0.1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToBookingDetails(context, bookingData, bookingId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '₹${bookingData['price']?.toString() ?? 'Not specified'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showRejectionDialog(context, onReject),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'REJECT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBookingDetails(
    BuildContext context,
    Map<String, dynamic> bookingData,
    String bookingId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(
          bookingData: bookingData,
          bookingId: bookingId,
          onAccept: () => _updateBookingStatus(
            context,
            bookingId: bookingId,
            workerId: FirebaseAuth.instance.currentUser?.uid,
            customerId: bookingData['customerId']?.toString(),
            status: 'accepted',
          ),
          onReject: (reason) => _updateBookingStatus(
            context,
            bookingId: bookingId,
            workerId: FirebaseAuth.instance.currentUser?.uid,
            customerId: bookingData['customerId']?.toString(),
            status: 'rejected',
            rejectionReason: reason,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.orange;
      default: // pending
        return Colors.amber;
    }
  }

  Future<void> _updateBookingStatus(
    BuildContext context, {
    required String bookingId,
    required String? workerId,
    required String? customerId,
    required String status,
    String rejectionReason = '',
  }) async {
    if (workerId == null || customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      // Update in all collections
      await Future.wait([
        db.collection('bookings').doc(bookingId).update({
          'status': status,
          'rejectionReason': rejectionReason,
          'updatedAt': now,
        }),
        db.collection('workers').doc(workerId)
            .collection('myBookedWorks').doc(bookingId).update({
          'status': status,
          'rejectionReason': rejectionReason,
          'updatedAt': now,
        }),
        db.collection('users').doc(customerId)
            .collection('myBookings').doc(bookingId).update({
          'status': status,
          'rejectionReason': rejectionReason,
          'updatedAt': now,
        }),
      ]);

      // Send notification
      await _sendNotificationToUser(
        customerId: customerId,
        bookingId: bookingId,
        status: status,
        rejectionReason: rejectionReason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotificationToUser({
    required String customerId,
    required String bookingId,
    required String status,
    String rejectionReason = '',
  }) async {
    final db = FirebaseFirestore.instance;
    
    String title = '';
    String message = '';

    if (status == 'accepted') {
      title = 'Booking Accepted';
      message = 'Your booking has been accepted by the worker';
    } else if (status == 'rejected') {
      title = 'Booking Rejected';
      message = 'Your booking was rejected. Reason: $rejectionReason';
    }

    await db.collection('users').doc(customerId)
        .collection('notifications').add({
      'title': title,
      'message': message,
      'type': 'booking_update',
      'bookingId': bookingId,
      'status': status,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _showRejectionDialog(BuildContext context, Function(String) onReject) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Rejection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for rejecting this booking',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.isNotEmpty) {
                          onReject(reasonController.text);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a rejection reason'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('SUBMIT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }
}

class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;
  final VoidCallback onAccept;
  final Function(String) onReject;

  const BookingDetailsScreen({
    Key? key,
    required this.bookingData,
    required this.bookingId,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = bookingData['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final bookingDate = _parseTimestamp(bookingData['bookingDateTime']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.grey.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Booking Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BOOKING INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.person,
                        label: 'Customer',
                        value: bookingData['customerName']?.toString(),
                      ),
                      _buildDetailRow(
                        icon: Icons.phone,
                        label: 'Customer Phone',
                        value: bookingData['customerPhone']?.toString(),
                      ),
                      _buildDetailRow(
                        icon: Icons.email,
                        label: 'Customer Email',
                        value: bookingData['customerEmail']?.toString(),
                      ),
                      _buildDetailRow(
                        icon: Icons.work,
                        label: 'Service',
                        value: bookingData['category']?.toString(),
                      ),
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Booking Date',
                        value: bookingDate != null
                            ? DateFormat('MMM dd, yyyy').format(bookingDate)
                            : null,
                      ),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Booking Time',
                        value: bookingDate != null
                            ? DateFormat('hh:mm a').format(bookingDate)
                            : null,
                      ),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: bookingData['address']?.toString(),
                      ),
                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: 'Price',
                        value: bookingData['price'] != null
                            ? '₹${bookingData['price']}'
                            : null,
                      ),
                      _buildDetailRow(
                        icon: Icons.payment,
                        label: 'Payment Method',
                        value: bookingData['paymentMethod']?.toString(),
                      ),
                      if (bookingData['additionalNotes'] != null)
                        _buildDetailRow(
                          icon: Icons.note,
                          label: 'Additional Notes',
                          value: bookingData['additionalNotes']?.toString(),
                        ),
                      if (bookingData['rejectionReason'] != null)
                        _buildDetailRow(
                          icon: Icons.block,
                          label: 'Rejection Reason',
                          value: bookingData['rejectionReason']?.toString(),
                          valueColor: Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dates Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATES',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.create,
                        label: 'Created At',
                        value: _formatTimestamp(bookingData['createdAt']),
                      ),
                      _buildDetailRow(
                        icon: Icons.update,
                        label: 'Updated At',
                        value: _formatTimestamp(bookingData['updatedAt']),
                      ),
                    ],
                  ),
                ),
              ),

              if (status == 'pending') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'ACCEPT BOOKING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showRejectionDialog(context, onReject),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'REJECT BOOKING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String? value,
    Color valueColor = Colors.black,
  }) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, Function(String) onReject) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Rejection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for rejecting this booking',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.isNotEmpty) {
                          onReject(reasonController.text);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a rejection reason'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('SUBMIT'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.orange;
      default: // pending
        return Colors.amber;
    }
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    final date = _parseTimestamp(timestamp);
    if (date == null) return 'Not specified';
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }
}
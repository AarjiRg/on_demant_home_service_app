import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerPendingWorksPage extends StatefulWidget {
  @override
  _WorkerPendingWorksPageState createState() => _WorkerPendingWorksPageState();
}

class _WorkerPendingWorksPageState extends State<WorkerPendingWorksPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _workerId;

  @override
  void initState() {
    super.initState();
    _workerId = _auth.currentUser?.uid ?? '';
  }

  Future<void> _completeWork(String bookingId) async {
    try {
      final workerRef = _firestore.collection('workers').doc(_workerId);
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      
      // Get the work document
      final docSnapshot = await workerRef.collection('myBookedWorks').doc(bookingId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Work document not found');
      }

      final workData = docSnapshot.data() as Map<String, dynamic>;
      
      // Batch write for atomic operations
      final batch = _firestore.batch();
      
      // Add to completed works
      batch.set(
        workerRef.collection('myCompletedWorks').doc(bookingId),
        workData,
      );
      
      // Remove from pending works
      batch.delete(workerRef.collection('myBookedWorks').doc(bookingId));
      
      // Update bookings collection
      batch.update(bookingRef, {'status': 'completed'});
      
      // Update user's myBookings collection
      final userBookingRef = _firestore
          .collection('users')
          .doc(workData['customerId'])
          .collection('myBookings')
          .doc(bookingId);
          
      batch.update(userBookingRef, {'status': 'completed'});

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work marked as completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing work: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Works'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('workers')
            .doc(_workerId)
            .collection('myBookedWorks')
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No accepted works found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final work = snapshot.data!.docs[index];
              final data = work.data() as Map<String, dynamic>;
              
              final bookingDate = (data['bookingDateTime'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(bookingDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Customer', data['customerName'] ?? 'N/A'),
                      _buildInfoRow('Address', data['address'] ?? 'Address not provided'),
                      _buildInfoRow('Date', formattedDate),
                      _buildInfoRow('Category', data['category'] ?? 'N/A'),
                      _buildInfoRow('Price', '₹${data['price'] ?? '0'}'),
                      _buildInfoRow('Payment Method', data['paymentMethod'] ?? 'N/A'),
                      
                      if (data['additionalNotes']?.isNotEmpty ?? false)
                        _buildInfoRow('Notes', data['additionalNotes']),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _completeWork(work.id),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
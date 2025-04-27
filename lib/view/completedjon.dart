import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CompletedJobsScreen extends StatelessWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Jobs History'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.teal.shade400],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: currentUserId != null
            ? FirebaseFirestore.instance
                .collection('workers')
                .doc(currentUserId)
                .collection('myCompletedWorks')
                .orderBy('bookingDateTime', descending: true)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Completed Jobs Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var jobData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildJobCard(jobData, dateFormat);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> jobData, DateFormat dateFormat) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobData['category']?.toString().toUpperCase() ?? 'SERVICE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Chip(
                  label: const Text('COMPLETED'),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 24),

            // Customer Details
            _buildSectionTitle('Customer Details'),
            _buildDetailRow(
              Icons.person,
              'Name',
              jobData['customerName'] ?? 'Not Available',
            ),
            _buildDetailRow(
              Icons.phone,
              'Phone',
              jobData['customerPhone'] ?? 'Not Provided',
            ),
            _buildDetailRow(
              Icons.email,
              'Email',
              jobData['customerEmail'] ?? 'No Email',
            ),
            _buildDetailRow(
              Icons.location_on,
              'Address',
              jobData['address'] ?? 'Address Not Specified',
            ),

            // Booking Timeline
            _buildSectionTitle('Booking Timeline'),
            _buildTimelineItem(
              'Booked At',
              dateFormat.format((jobData['createdAt'] as Timestamp).toDate()),
            ),
            _buildTimelineItem(
              'Scheduled For',
              dateFormat.format((jobData['bookingDateTime'] as Timestamp).toDate()),
            ),
            _buildTimelineItem(
              'Completed At',
              dateFormat.format((jobData['updatedAt'] as Timestamp).toDate()),
              isLast: true,
            ),

            // Payment Info
            _buildSectionTitle('Payment Information'),
            _buildDetailRow(
              Icons.attach_money,
              'Amount',
              '₹${jobData['price'] ?? '0'}',
            ),
            _buildDetailRow(
              Icons.payment,
              'Method',
              jobData['paymentMethod']?.toString().toUpperCase() ?? 'CASH',
            ),

            // Additional Notes
            if ((jobData['additionalNotes']?.toString().isNotEmpty ?? false))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Special Instructions'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      jobData['additionalNotes'],
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),

            // Worker Details
            _buildSectionTitle('My Service Details'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                backgroundImage: jobData['workerImage']?.toString().isNotEmpty ?? false
                    ? NetworkImage(jobData['workerImage'])
                    : null,
                child: jobData['workerImage']?.toString().isEmpty ?? true
                    ? Icon(Icons.person, color: Colors.blue.shade800)
                    : null,
              ),
              title: Text(
                jobData['workerName'] ?? 'Worker Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(jobData['workerPhone'] ?? 'Contact Not Available'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade800),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildTimelineItem(String title, String date, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                Icons.circle,
                size: 16,
                color: Colors.blue.shade800,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
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
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserNotificationsPage extends StatelessWidget {
  const UserNotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.mark_as_unread),
            onPressed: () => _markAllAsRead(userId),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp).toDate();

              return Dismissible(
                key: Key(notification.id),
                background: Container(color: Colors.red),
                onDismissed: (_) => _deleteNotification(userId, notification.id),
                child: ListTile(
                  leading: Icon(_getNotificationIcon(data['type']), color: _getNotificationColor(data)),
                  title: Text(data['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message']),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(date),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: data['isRead'] == true
                      ? null
                      : Icon(Icons.circle, color: Colors.blue, size: 12),
                  onTap: () => _handleNotificationTap(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_update':
        return Icons.calendar_today;
      case 'new_booking':
        return Icons.work;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(Map<String, dynamic> data) {
    if (data['status'] == 'rejected') return Colors.red;
    if (data['status'] == 'accepted') return Colors.green;
    return Colors.blue;
  }

  Future<void> _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Mark as read
    if (data['isRead'] != true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(data['id'])
          .update({'isRead': true});
    }

    // Navigate to booking details if applicable
    if (data['bookingId'] != null) {
      // Implement navigation to booking details
    }
  }

  Future<void> _deleteNotification(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> _markAllAsRead(String userId) async {
    final notifications = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
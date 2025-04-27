import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentUserId,
          ),
        ],
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildNotificationItem(
            snapshot.data!.docs[index],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Handle null values with defaults
    final title = data['title'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final isRead = data['isRead'] as bool? ?? false;
    final type = data['type'] as String? ?? 'general';
    final status = data['status'] as String? ?? '';
    final bookingId = data['bookingId'] as String? ?? '';
    
    Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp != null 
        ? DateFormat('dd MMMM yyyy \'at\' HH:mm').format(timestamp.toDate())
        : 'Unknown time';

    // Determine card color based on status
    Color cardColor = isRead ? Colors.grey[100]! : Colors.blue[50]!;
    if (status == 'rejected') {
      cardColor = isRead ? Colors.red[50]! : Colors.red[100]!;
    } else if (status == 'approved') {
      cardColor = isRead ? Colors.green[50]! : Colors.green[100]!;
    } else if (status == 'pending') {
      cardColor = isRead ? Colors.orange[50]! : Colors.orange[100]!;
    }

    return Dismissible(
      key: Key(doc.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe right to left - mark as read
          if (!isRead) {
            await doc.reference.update({'isRead': true});
          }
          return false;
        } else {
          // Swipe left to right - delete
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          doc.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cardColor,
        child: ListTile(
          leading: _getNotificationIcon(type, status),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              color: status == 'rejected' ? Colors.red[800] : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 4),
              Text(createdAt, style: const TextStyle(fontSize: 12)),
              if (bookingId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Booking ID: $bookingId', style: const TextStyle(fontSize: 12)),
              ],
              if (status.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          trailing: isRead 
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(doc),
                )
              : const Icon(Icons.circle, color: Colors.blue, size: 12),
          onTap: () {
            if (!isRead) {
              doc.reference.update({'isRead': true});
            }
          },
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type, String status) {
    if (status == 'rejected') {
      return const Icon(Icons.cancel, color: Colors.red);
    } else if (status == 'approved') {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (status == 'pending') {
      return const Icon(Icons.access_time, color: Colors.orange);
    }

    switch (type) {
      case 'booking_update':
        return const Icon(Icons.assignment, color: Colors.blue);
      case 'payment':
        return const Icon(Icons.payment, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.orange);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'rejected':
        return Colors.red[800]!;
      case 'approved':
        return Colors.green[800]!;
      case 'pending':
        return Colors.orange[800]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
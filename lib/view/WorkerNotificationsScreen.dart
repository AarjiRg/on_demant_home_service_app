import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<WorkerNotificationsScreen> createState() => _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _getCurrentWorkerId();
  }

  Future<void> _getCurrentWorkerId() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _workerId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_workerId == null) {
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
            onPressed: _getCurrentWorkerId,
          ),
        ],
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(_workerId)
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
    final title = data['title'] as String? ?? 'No Title';
    final message = data['message'] as String? ?? '';
    final isRead = data['isRead'] as bool? ?? false;
    final type = data['type'] as String? ?? 'unknown';
    
    Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp != null 
        ? DateFormat('dd MMMM yyyy \'at\' HH:mm').format(timestamp.toDate())
        : 'Unknown time';

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
        color: isRead ? Colors.grey[100] : Colors.blue[50],
        child: ListTile(
          leading: _getNotificationIcon(type),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 4),
              Text(createdAt, style: const TextStyle(fontSize: 12)),
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

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'new_booking':
        return const Icon(Icons.assignment, color: Colors.green);
      case 'booking_update':
        return const Icon(Icons.update, color: Colors.blue);
      case 'payment':
        return const Icon(Icons.payment, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.orange);
    }
  }
}
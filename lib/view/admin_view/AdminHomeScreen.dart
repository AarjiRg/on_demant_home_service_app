import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_demant_home_service_app/view/startup_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  int totalUsers = 0;
  int totalWorkers = 0;
  int totalBookings = 0;
  int activeBookings = 0;
  double totalRevenue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('workers').get(),
        _firestore.collection('bookings').get(),
        _firestore.collection('bookings').where('status', isEqualTo: 'completed').get(),
      ]);

      setState(() {
        totalUsers = results[0].size;
        totalWorkers = results[1].size;
        totalBookings = results[2].size;
        activeBookings = totalBookings - results[3].size;
        
        totalRevenue = results[3].docs.fold(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (double.tryParse(data['price']?.toString() ?? '0') ?? 0);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.teal.shade400],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getCurrentTab(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Future<void> _signOut() async {
await FirebaseAuth.instance.signOut();
Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeScreen(),));
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.engineering),
              label: 'Workers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Reviews',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildWorkersTab();
      case 3:
        return _buildBookingsTab();
      case 4:
        return _buildReviewsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatContainer(
                title: 'Total Users',
                value: totalUsers,
                icon: Icons.people,
                color: Colors.blue.shade400,
              ),
              _buildStatContainer(
                title: 'Total Workers',
                value: totalWorkers,
                icon: Icons.engineering,
                color: Colors.orange.shade400,
              ),
              _buildStatContainer(
                title: 'Total Bookings',
                value: totalBookings,
                icon: Icons.book,
                color: Colors.green.shade400,
              ),
              _buildStatContainer(
                title: 'Active Bookings',
                value: activeBookings,
                icon: Icons.event_available,
                color: Colors.purple.shade400,
              ),
              _buildRevenueContainer(
                title: 'Total Revenue',
                value: totalRevenue,
                icon: Icons.attach_money,
                color: Colors.teal.shade400,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Bookings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('bookings')
                  .orderBy('bookingDateTime', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent bookings'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var booking = snapshot.data!.docs[index];
                    var data = booking.data() as Map<String, dynamic>;
                    return _buildBookingItem(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatContainer({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueContainer({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> data) {
    final bookingDateTime = _parseTimestamp(data['bookingDateTime']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book_online, color: Colors.blue),
        ),
        title: Text(
          data['category'] ?? 'Unknown Service',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${data['customerName'] ?? 'Unknown'} - ${data['workerName'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (bookingDateTime != null)
              Text(
                '${_dateFormat.format(bookingDateTime)} at ${_timeFormat.format(bookingDateTime)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(data['status']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: TextStyle(
                  color: _getStatusColor(data['status']),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${data['price'] ?? '0'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        onTap: () => _showBookingDetails(data),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users')
       
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No regular users found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var user = snapshot.data!.docs[index];
            var data = user.data() as Map<String, dynamic>;
            return _buildUserItem(data, user.id);
          },
        );
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> data, String userId) {
    // Format the registration date
    String formattedDate = 'Not available';
    if (data['registeredAt'] != null) {
      final date = (data['registeredAt'] as Timestamp).toDate();
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            data['name']?.toString().isNotEmpty == true 
                ? data['name'][0].toUpperCase()
                : 'U',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          '${data['name'] ?? 'Unknown'} ${data['lastname'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (data['phone'] != null)
              Text(
                'Phone: ${data['phone']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            if (data['location'] != null)
              Text(
                'Location: ${data['location']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            Text(
              'Registered: $formattedDate',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showUserOptions(userId, '${data['name']} ${data['lastname']}'),
        ),
        onTap: () => _showUserDetails(data),
      ),
    );
  }

  Widget _buildWorkersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('workers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No workers found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var worker = snapshot.data!.docs[index];
            var data = worker.data() as Map<String, dynamic>;
            return _buildWorkerItem(data, worker.id);
          },
        );
      },
    );
  }

  Widget _buildWorkerItem(Map<String, dynamic> data, String workerId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: data['profileImage'] != null
              ? CachedNetworkImageProvider(data['profileImage'])
              : null,
          child: data['profileImage'] == null 
              ? const Icon(Icons.engineering)
              : null,
        ),
        title: Text(
          data['fullName'] ?? 'Unknown Worker',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['serviceCategory'] ?? 'No category',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  data['rating']?.toStringAsFixed(1) ?? '0.0',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showWorkerOptions(workerId, data['fullName'] ?? 'Worker'),
        ),
        onTap: () => _showWorkerDetails(data),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bookings')
          .orderBy('bookingDateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var booking = snapshot.data!.docs[index];
            var data = booking.data() as Map<String, dynamic>;
            return _buildBookingItem(data);
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collectionGroup('reviews').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reviews found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var review = snapshot.data!.docs[index];
            var data = review.data() as Map<String, dynamic>;
            return _buildReviewItem(data, review.reference);
          },
        );
      },
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> data, DocumentReference reference) {
    final timestamp = _parseTimestamp(data['timestamp']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: data['userImage'] != null
              ? CachedNetworkImageProvider(data['userImage'])
              : null,
          child: data['userImage'] == null 
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          data['userName'] ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) => Icon(
                Icons.star,
                size: 16,
                color: i < (data['rating'] as num? ?? 0) ? Colors.amber : Colors.grey,
              )),
            ),
            const SizedBox(height: 4),
            Text(
              data['reviewText'] ?? 'No review text',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _dateFormat.format(timestamp),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteReviewDialog(reference),
        ),
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  Future<void> _showUserOptions(String userId, String userName) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockUserDialog(userId, userName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement edit functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBlockUserDialog(String userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Block $userName?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will prevent the user from accessing the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _blockUser(userId, true);
                    },
                    child: const Text('Block', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _blockUser(String userId, bool blocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blocked': blocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${blocked ? 'blocked' : 'unblocked'} successfully'),
          backgroundColor: blocked ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  void _showUserDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: data['profileImage'] != null
                      ? CachedNetworkImageProvider(data['profileImage'])
                      : null,
                  child: data['profileImage'] == null 
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Name', data['fullName'] ?? '${data['name'] ?? 'Unknown'} ${data['lastname'] ?? ''}'),
              _buildDetailItem('Email', data['email'] ?? 'No email'),
              _buildDetailItem('Phone', data['phone'] ?? 'Not provided'),
              if (data['address'] != null) 
                _buildDetailItem('Address', data['address']),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> data) {
    final bookingDateTime = _parseTimestamp(data['bookingDateTime']);
    final createdAt = _parseTimestamp(data['createdAt']);
    final updatedAt = _parseTimestamp(data['updatedAt']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.book_online, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Service', data['category'] ?? 'Unknown'),
              _buildDetailItem('Customer', data['customerName'] ?? 'Unknown'),
              _buildDetailItem('Customer Phone', data['customerPhone'] ?? 'Not provided'),
              _buildDetailItem('Worker', data['workerName'] ?? 'Unknown'),
              _buildDetailItem('Worker Phone', data['workerPhone'] ?? 'Not provided'),
              _buildDetailItem('Status', data['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailItem('Price', '₹${data['price'] ?? '0'}'),
              _buildDetailItem('Payment Method', data['paymentMethod'] ?? 'Not specified'),
              if (bookingDateTime != null)
                _buildDetailItem('Booking Date', '${_dateFormat.format(bookingDateTime)} at ${_timeFormat.format(bookingDateTime)}'),
              if (data['address'] != null) 
                _buildDetailItem('Address', data['address']),
              if (data['additionalNotes'] != null) 
                _buildDetailItem('Notes', data['additionalNotes']),
              if (createdAt != null)
                _buildDetailItem('Created At', '${_dateFormat.format(createdAt)} at ${_timeFormat.format(createdAt)}'),
              if (updatedAt != null)
                _buildDetailItem('Updated At', '${_dateFormat.format(updatedAt)} at ${_timeFormat.format(updatedAt)}'),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWorkerOptions(String workerId, String workerName) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Verify Worker'),
                onTap: () {
                  Navigator.pop(context);
                  _verifyWorker(workerId, true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block Worker'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockWorkerDialog(workerId, workerName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyWorker(String workerId, bool verified) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'verified': verified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Worker ${verified ? 'verified' : 'unverified'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update worker: $e')),
      );
    }
  }

  Future<void> _showBlockWorkerDialog(String workerId, String workerName) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Block $workerName?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will prevent the worker from accessing the app and receiving bookings.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _blockWorker(workerId, true);
                    },
                    child: const Text('Block', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _blockWorker(String workerId, bool blocked) async {
    try {
      await _firestore.collection('workers').doc(workerId).update({
        'blocked': blocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Worker ${blocked ? 'blocked' : 'unblocked'} successfully'),
          backgroundColor: blocked ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update worker: $e')),
      );
    }
  }

  void _showWorkerDetails(Map<String, dynamic> data) {
    final createdAt = _parseTimestamp(data['createdAt']);
    final updatedAt = _parseTimestamp(data['updatedAt']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: data['profileImage'] != null
                      ? CachedNetworkImageProvider(data['profileImage'])
                      : null,
                  child: data['profileImage'] == null 
                      ? const Icon(Icons.engineering, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Name', data['fullName'] ?? 'Unknown Worker'),
              _buildDetailItem('Email', data['email'] ?? 'No email'),
              _buildDetailItem('Phone', data['phone'] ?? 'Not provided'),
              _buildDetailItem('Service', data['serviceCategory'] ?? 'No category'),
              _buildDetailItem('Title', data['title'] ?? 'Not specified'),
              _buildDetailItem('Description', data['description'] ?? 'Not provided'),
              _buildDetailItem('About Me', data['aboutMe'] ?? 'Not provided'),
              _buildDetailItem('Rating', data['rating']?.toStringAsFixed(1) ?? '0.0'),
              _buildDetailItem('Experience', '${data['yearsExperience'] ?? '0'} years'),
              _buildDetailItem('Hourly Rate', '₹${data['hourlyRate'] ?? '0'}'),
              _buildDetailItem('Status', data['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              _buildDetailItem('Verified', data['verified'] == true ? 'Yes' : 'No'),
              _buildDetailItem('Address', data['address'] ?? 'Not provided'),
              _buildDetailItem('City', data['city'] ?? 'Not provided'),
              _buildDetailItem('State', data['state'] ?? 'Not provided'),
              _buildDetailItem('Pincode', data['pincode'] ?? 'Not provided'),
              _buildDetailItem('Country', data['country'] ?? 'Not provided'),
              if (createdAt != null)
                _buildDetailItem('Created At', '${_dateFormat.format(createdAt)} at ${_timeFormat.format(createdAt)}'),
              if (updatedAt != null)
                _buildDetailItem('Updated At', '${_dateFormat.format(updatedAt)} at ${_timeFormat.format(updatedAt)}'),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteReviewDialog(DocumentReference reference) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Delete Review?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete the review.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await reference.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review deleted successfully'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/MyBookingsScreen.dart';
import 'package:on_demant_home_service_app/view/startup_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImage(_auth.currentUser!.uid);
    }
  }

  Future<void> _uploadImage(String userId) async {
    if (_selectedImage == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId.jpg');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _currentUserData != null) {
        _nameController.text = _currentUserData!['name'] ?? '';
        _phoneController.text = _currentUserData!['phone'] ?? '';
        _addressController.text = _currentUserData!['address'] ?? '';
      }
    });
  }

  Future<void> _saveProfileChanges(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _showReviewDialog() {
    TextEditingController reviewController = TextEditingController();
    double tempRating = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Submit Review', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(
                        index < tempRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () => setState(() => tempRating = index + 1.0),
                    )),
                  ),
                  TextField(
                    controller: reviewController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Write your review here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      if (tempRating > 0) {
                        await _submitReview(tempRating, reviewController.text);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Submit Review', 
                      style: TextStyle(color: Colors.white)),)
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(double rating, String comment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reviewData = {
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('users').doc(user.uid)
        .collection('myAppReviews').add(reviewData);
      await _firestore.collection('allReviews').add(reviewData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEditing,
            ),
        ],
      ),
      body: user == null 
          ? Center(child: Text("Please login to view profile"))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: CircularProgressIndicator());
                }
                
                _currentUserData = snapshot.data!.data() as Map<String, dynamic>;
                final joinedDate = (_currentUserData!['joinedDate'] as Timestamp?)?.toDate();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.blue.shade800, Colors.blue.shade400],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundImage: NetworkImage(
                                      (_currentUserData!['profileImageUrl'] as String?) ?? 
                                      'https://cdn-icons-png.flaticon.com/512/149/149071.png'),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black12, blurRadius: 6)
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt, color: Colors.blue),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            _isEditing
                                ? Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40),
                                    child: TextField(
                                      controller: _nameController,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter your name',
                                        hintStyle: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  )
                                : Text(
                                    (_currentUserData!['name'] as String?) ?? 'No Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            Text(
                              user.email ?? '',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              icon: Icons.person,
                              title: 'Personal Info',
                              children: [
                                _isEditing
                                    ? _buildEditableInfoRow(
                                        Icons.phone, 
                                        'Phone', 
                                        _phoneController,
                                        TextInputType.phone,
                                      )
                                    : _buildInfoRow(
                                        Icons.phone, 
                                        'Phone', 
                                        (_currentUserData!['phone'] as String?) ?? 'Not provided'
                                      ),
                                _isEditing
                                    ? _buildEditableInfoRow(
                                        Icons.location_on, 
                                        'Address', 
                                        _addressController,
                                        TextInputType.streetAddress,
                                      )
                                    : _buildInfoRow(
                                        Icons.location_on, 
                                        'Address', 
                                        (_currentUserData!['address'] as String?) ?? 'Not provided'
                                      ),
                                _buildInfoRow(
                                  Icons.date_range, 
                                  'Member since', 
                                  joinedDate != null 
                                      ? DateFormat('MMM d, yyyy').format(joinedDate) 
                                      : 'N/A'
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildInfoCard(
                              icon: Icons.star,
                              title: 'App Reviews',
                              children: [
                                ListTile(
                                  leading: Icon(Icons.rate_review, color: Colors.amber),
                                  title: Text('Submit Review'),
                                  trailing: Icon(Icons.chevron_right),
                                  onTap: _showReviewDialog,
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore.collection('users').doc(user.uid)
                                    .collection('myAppReviews').snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return SizedBox();
                                    return Column(
                                      children: snapshot.data!.docs.map((doc) {
                                        final review = doc.data() as Map<String, dynamic>;
                                        return ListTile(
                                          title: Text(
                                            'Rating: ${(review['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}/5'
                                          ),
                                          subtitle: Text(
                                            (review['comment'] as String?) ?? ''
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildInfoCard(
                              icon: Icons.settings,
                              title: 'Account Settings',
                              children: [
                                _buildActionButton(
                                  'View Bookings', 
                                  Icons.calendar_today, 
                                  Colors.blue, 
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MyBookingsScreen()
                                    ),
                                  ),
                                ),
                                _buildActionButton(
                                  'Logout', 
                                  Icons.logout, 
                                  Colors.red, 
                                  () async {
                                    await FirebaseAuth.instance.signOut(); 
                                    Navigator.pushReplacement(context, 
                                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                                  }
                                ),
                              ],
                            ),
                            if (_isEditing) ...[
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _saveProfileChanges(user.uid),
                                      child: Text('Save Changes', 
                                        style: TextStyle(color: Colors.white, fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 28),
                SizedBox(width: 10),
                Text(title, 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, 
                style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String label, TextEditingController controller, TextInputType inputType) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
                TextField(
                  controller: controller,
                  keyboardType: inputType,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Enter $label',
                  ),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onPressed,
    );
  }
}

class WorkerBookingsScreen extends StatelessWidget {
  final String workerId;

  const WorkerBookingsScreen({required this.workerId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Bookings"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('workerId', isEqualTo: workerId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No bookings found.", 
              style: TextStyle(color: Colors.grey)));
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final booking = doc.data() as Map<String, dynamic>;
              final date = (booking['timestamp'] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(Icons.assignment, color: Colors.blue),
                  title: Text((booking['serviceType'] as String?) ?? 'Service Booking'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${(booking['customerName'] as String?) ?? 'Unknown'}'),
                      Text('Date: ${date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A'}'),
                      Text('Status: ${(booking['status'] as String?) ?? 'Unknown'}'),
                    ],
                  ),
                  trailing: Chip(
                    backgroundColor: _getStatusColor(
                      (booking['status'] as String?) ?? ''),
                    label: Text(
                      (booking['status'] as String?) ?? 'Unknown',
                      style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
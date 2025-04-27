import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({Key? key}) : super(key: key);

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  late DocumentReference _workerRef;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _localImage;
  String? _profileImageUrl;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userId = _auth.currentUser?.uid ?? '';
    _workerRef = _firestore.collection('workers').doc(userId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _localImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_localImage == null) return null;
    
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid ?? '';
      final ref = _storage.ref().child('worker_profiles/$userId.jpg');
      await ref.putFile(_localImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleEditing() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newImageUrl = await _uploadImage();
      
      await _workerRef.update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        if (newImageUrl != null) 'profileImage': newImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      
      setState(() {
        _isEditing = false;
        if (newImageUrl != null) {
          _profileImageUrl = newImageUrl;
          _localImage = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _localImage = null;
    });
  }

  Widget _buildProfileImage(Map<String, dynamic>? worker) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _getProfileImage(worker),
          child: _getProfileImage(worker) == null
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
      ],
    );
  }

  ImageProvider? _getProfileImage(Map<String, dynamic>? worker) {
    if (_localImage != null) return FileImage(_localImage!);
    if (_profileImageUrl != null) return NetworkImage(_profileImageUrl!);
    if (worker?['profileImage'] != null) return NetworkImage(worker!['profileImage']);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isLoading ? null : _toggleEditing,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade800, Colors.teal.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: _workerRef.snapshots(),
                            builder: (context, snapshot) {
                              final worker = snapshot.data?.data() as Map<String, dynamic>?;
                              return _buildProfileImage(worker);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileSection(),
                    _buildStatisticsSection(),
                    _buildReviewsSection(),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _workerRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final worker = snapshot.data!.data() as Map<String, dynamic>;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isEditing
                  ? _buildEditForm(worker)
                  : _buildProfileInfo(worker),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> worker) {
    return Column(
      children: [
        Text(
          worker['name'] ?? 'Worker Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          worker['email'] ?? 'No email provided',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.phone, 'Contact', worker['phone'] ?? 'Not provided'),
        _buildInfoRow(Icons.location_on, 'Address', worker['address'] ?? 'Not specified'),
      ],
    );
  }

  Widget _buildEditForm(Map<String, dynamic> worker) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value?.isEmpty ?? true ? 'Please enter your phone number' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) => value?.isEmpty ?? true ? 'Please enter your address' : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelEditing,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Work Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                title: 'Active Jobs',
                valueStream: _workerRef.collection('myBookedWorks')
                    .where('status', isEqualTo: 'accepted')
                    .snapshots()
                    .map((snap) => snap.size.toString()),
                icon: Icons.assignment,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Completed Jobs',
                valueStream: _workerRef.collection('myCompletedWorks')
                    .snapshots()
                    .map((snap) => snap.size.toString()),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Total Revenue',
                valueStream: _workerRef.collection('myCompletedWorks')
                    .snapshots()
                    .map<double>((snap) {
                      return snap.docs.fold<double>(0, (sum, doc) {
                        final price = doc['price'];
                        if (price is num) return sum + price.toDouble();
                        if (price is String) return sum + (double.tryParse(price) ?? 0);
                        return sum;
                      });
                    })
                    .map<String>((sum) => '₹${sum.toStringAsFixed(0)}'),
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
              _buildStatCard(
                title: 'Average Rating',
                valueStream: _workerRef.collection('reviews')
                    .snapshots()
                    .map<double>((snap) => snap.docs.isEmpty 
                        ? 0.0 
                        : snap.docs.fold<double>(0, (sum, doc) => sum + (doc['rating'] as num).toDouble()) / snap.docs.length)
                    .map<String>((avg) => avg.toStringAsFixed(1)),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _workerRef.collection('reviews')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return Text(
                  'No reviews yet',
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildReviewCard(review);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildStatCard({
    required String title,
    required Stream<String> valueStream,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            StreamBuilder<String>(
              stream: valueStream,
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? '0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage: review['userImage'] != null 
              ? NetworkImage(review['userImage']) 
              : null,
          child: review['userImage'] == null
              ? Icon(Icons.person, color: Colors.blue.shade800)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review['userName'] ?? 'Anonymous',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  ...List.generate(5, (index) => Icon(
                    index < (review['rating'] as num? ?? 0) 
                        ? Icons.star 
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ],
              ),
              if (review['reviewText']?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    review['reviewText'],
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              if (review['timestamp'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(
                      (review['timestamp'] as Timestamp).toDate()),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
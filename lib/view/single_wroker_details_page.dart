import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:on_demant_home_service_app/view/book_worker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SingleWorkerViewPage extends StatefulWidget {
  final DocumentSnapshot worker;

  const SingleWorkerViewPage({required this.worker, super.key});

  @override
  State<SingleWorkerViewPage> createState() => _SingleWorkerViewPageState();
}

class _SingleWorkerViewPageState extends State<SingleWorkerViewPage> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerData = widget.worker.data() as Map<String, dynamic>;
    final emergencyContact = workerData['emergencyContact'] as Map? ?? {};
    final availableHours = workerData['availableHours'] as Map? ?? {};
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
    final surfaceColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(workerData['fullName'] ?? 'Worker Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.white),
            onPressed: () => _callWorker(workerData['phone']),
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareWorkerDetails(workerData),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(workerData),
            ),
            pinned: true,
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Summary
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerData['fullName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    workerData['serviceCategory'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    workerData['rating']?.toStringAsFixed(1) ?? '0.0',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.work_history,
                              text: '${workerData['yearsExperience'] ?? '0'} yrs exp',
                            ),
                            SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.location_on,
                              text: workerData['city'] ?? '',
                            ),
                            SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.monetization_on,
                              text: '₹${workerData['hourlyRate']}/hr',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1),

                  // About Section
                  _buildSection(
                    title: "About",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workerData['aboutMe'] ?? 'No description provided',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        _buildDetailItem(
                          icon: Icons.transgender,
                          title: "Gender",
                          value: workerData['gender'] ?? 'Not specified',
                        ),
                        _buildDetailItem(
                          icon: Icons.cake,
                          title: "Date of Birth",
                          value: workerData['dob'] ?? 'Not specified',
                        ),
                        _buildDetailItem(
                          icon: Icons.language,
                          title: "Languages",
                          value: (workerData['languagesSpoken'] as List?)?.join(', ') ?? 'None',
                        ),
                      ],
                    ),
                  ),

                  // Contact Information
                  _buildSection(
                    title: "Contact Information",
                    child: Column(
                      children: [
                        _buildDetailItem(
                          icon: Icons.phone,
                          title: "Phone",
                          value: workerData['phone'] ?? 'Not available',
                          isImportant: true,
                        ),
                        _buildDetailItem(
                          icon: Icons.email,
                          title: "Email",
                          value: workerData['email'] ?? 'Not available',
                        ),
                        _buildDetailItem(
                          icon: Icons.location_on,
                          title: "Address",
                          value: [
                            workerData['address'],
                            workerData['city'],
                            workerData['state'],
                            workerData['pincode'],
                            workerData['country'],
                          ].where((e) => e != null && e.isNotEmpty).join(', '),
                        ),
                        _buildDetailItem(
                          icon: Icons.emergency,
                          title: "Emergency Contact",
                          value: emergencyContact['name'] != null 
                              ? '${emergencyContact['name']} (${emergencyContact['number']})' 
                              : 'Not provided',
                        ),
                      ],
                    ),
                  ),

                  // Professional Details
                  _buildSection(
                    title: "Professional Details",
                    child: Column(
                      children: [
                        _buildDetailItem(
                          icon: Icons.work,
                          title: "Service Category",
                          value: workerData['serviceCategory'] ?? 'Not specified',
                        ),
                        _buildDetailItem(
                          icon: Icons.build,
                          title: "Skills",
                          value: (workerData['skills'] as List?)?.join(', ') ?? 'None',
                        ),
                        _buildDetailItem(
                          icon: Icons.access_time,
                          title: "Experience",
                          value: '${workerData['yearsExperience'] ?? '0'} years',
                        ),
                        _buildDetailItem(
                          icon: Icons.schedule,
                          title: "Availability",
                          value: _getAvailabilityText(workerData),
                        ),
                        _buildDetailItem(
                          icon: Icons.location_city,
                          title: "Preferred Locations",
                          value: (workerData['preferredLocations'] as List?)?.join(', ') ?? 'Anywhere',
                        ),
                        _buildDetailItem(
                          icon: Icons.beach_access,
                          title: "Works on Holidays",
                          value: (workerData['workOnHolidays'] ?? false) ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),

                  // Pricing
                  _buildSection(
                    title: "Pricing",
                    child: Column(
                      children: [
                        _buildDetailItem(
                          icon: Icons.monetization_on,
                          title: "Hourly Rate",
                          value: '₹${workerData['hourlyRate'] ?? '0'}',
                          isImportant: true,
                        ),
                        _buildDetailItem(
                          icon: Icons.calendar_today,
                          title: "Full Day Price",
                          value: '₹${workerData['fullDayPrice'] ?? 'Not specified'}',
                        ),
                      ],
                    ),
                  ),

                  // Identification
                  if (workerData['idProof'] != null || workerData['certification'] != null)
                    _buildSection(
                      title: "Identification",
                      child: Column(
                        children: [
                          if (workerData['idProof'] != null)
                            _buildImageItem(
                              title: "ID Proof (${workerData['idType']})",
                              imageUrl: workerData['idProof'],
                            ),
                          if (workerData['certification'] != null)
                            _buildImageItem(
                              title: "Certification",
                              imageUrl: workerData['certification'],
                            ),
                        ],
                      ),
                    ),

                  // Gallery
                  if ((workerData['workImages'] as List?)?.isNotEmpty == true || 
                      (workerData['previousWorkImages'] as List?)?.isNotEmpty == true)
                    _buildSection(
                      title: "Gallery",
                      child: Column(
                        children: [
                          if ((workerData['workImages'] as List?)?.isNotEmpty == true)
                            _buildGallerySection("Current Work", workerData['workImages']),
                          if ((workerData['previousWorkImages'] as List?)?.isNotEmpty == true)
                            _buildGallerySection("Previous Work", workerData['previousWorkImages']),
                        ],
                      ),
                    ),

                  // Reviews
                  _buildSection(
                    title: "Customer Reviews",
                    child: _buildReviewsSection(widget.worker.id),
                  ),

                  // Add Review
                  if (FirebaseAuth.instance.currentUser != null)
                    _buildSection(
                      title: "Add Your Review",
                      child: _buildAddReviewSection(widget.worker.id),
                    ),

                  // Book Now Button
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookWorkerScreen(
                                
                                workerImage: '',
                                workImages: [],
                                workerId: workerData['userId'],
                                workerName: workerData['fullName'],
                                category: workerData['serviceCategory'],
                                location: workerData['address'],
                                price: workerData['hourlyRate'],
                                phoneNumber: workerData['phone'],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "BOOK NOW",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> workerData) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: workerData['coverImage'] ?? workerData['profileImage'],
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.black.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 48,
              backgroundImage: workerData['profileImage'] != null 
                  ? CachedNetworkImageProvider(workerData['profileImage'])
                  : null,
              child: workerData['profileImage'] == null 
                  ? Icon(Icons.person, size: 40) 
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
        Divider(height: 40, thickness: 1),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String? value,
    bool isImportant = false,
  }) {
    if (value == null || value.isEmpty) return SizedBox();
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: isImportant ? Theme.of(context).primaryColor : Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                    color: isImportant ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem({required String title, required String imageUrl}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullImage(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(String title, List<dynamic> imageUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showFullImage(imageUrls[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsSection(String workerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            "No reviews yet",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((reviewDoc) {
              final review = reviewDoc.data() as Map<String, dynamic>;
              return _buildReviewItem(review);
            }).toList(),
            if (snapshot.data!.docs.length >= 3)
              TextButton(
                onPressed: () {
                  // TODO: Implement view all reviews
                },
                child: Text("View all reviews"),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timestamp = review['timestamp']?.toDate() ?? DateTime.now();

    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review['userImage'] != null
                    ? NetworkImage(review['userImage'])
                    : null,
                child: review['userImage'] == null
                    ? Icon(Icons.person)
                    : null,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['userName'] ?? 'Anonymous',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      ...List.generate(5, (index) => Icon(
                        Icons.star,
                        size: 16,
                        color: index < (review['rating'] as num).toInt()
                            ? Colors.amber
                            : Colors.grey[300],
                      )),
                      SizedBox(width: 8),
                      Text(
                        dateFormat.format(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            review['reviewText'] ?? '',
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection(String workerId) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  Icons.star,
                  size: 32,
                  color: index < _rating ? Colors.amber : Colors.grey[300],
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _reviewController,
            decoration: InputDecoration(
              labelText: "Write your review...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please write your review';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitReview(workerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "SUBMIT REVIEW",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAvailabilityText(Map<String, dynamic> workerData) {
    final availableDays = workerData['availableDays'] as List? ?? [];
    final availableHours = workerData['availableHours'] as Map? ?? {};
    
    final startTime = availableHours['start'] ?? '9:00';
    final endTime = availableHours['end'] ?? '17:00';
    
    if (availableDays.isEmpty) return 'Not available';
    
    return '${availableDays.join(', ')} from $startTime to $endTime';
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
           
           
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview(String workerId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userImage': user.photoURL,
        'rating': _rating,
        'reviewText': _reviewController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _updateWorkerRating(workerId);

      _reviewController.clear();
      setState(() => _rating = 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _updateWorkerRating(String workerId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final averageRating = totalRating / reviewsSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('workers')
        .doc(workerId)
        .update({
          'rating': averageRating,
          'completedJobs': reviewsSnapshot.docs.length,
        });
  }

  void _callWorker(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch call'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _shareWorkerDetails(Map<String, dynamic> workerData) {
    Share.share(
      "🌟 Professional Profile 🌟\n\n"
      "👷 ${workerData['fullName']}\n"
      "🏆 ${workerData['serviceCategory']} Professional\n"
      "⭐ Rating: ${workerData['rating']?.toStringAsFixed(1) ?? '0.0'} (${workerData['completedJobs'] ?? 0} jobs)\n"
      "💼 ${workerData['yearsExperience']} years experience\n"
      "📍 ${[
        workerData['address'],
        workerData['city'],
        workerData['state']
      ].where((e) => e != null && e.isNotEmpty).join(', ')}\n\n"
      "🔧 Skills: ${(workerData['skills'] as List?)?.join(', ') ?? 'None'}\n"
      "💰 Hourly Rate: ₹${workerData['hourlyRate']}\n"
      "📞 Contact: ${workerData['phone']}\n\n"
      "Found via On-Demand Home Service App",
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/single_wroker_details_page.dart';

class CategoryWorkersScreen extends StatelessWidget {
  final String category;

  const CategoryWorkersScreen({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("$category Professionals", 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workers')
            .where('serviceCategory', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error fetching workers",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No professionals found",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We couldn't find any $category professionals in your area",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 24.0 : 12.0,
              vertical: 12.0,
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLargeScreen ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isLargeScreen ? 1.8 : 1.4,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var worker = snapshot.data!.docs[index];
                var workerData = worker.data() as Map<String, dynamic>;

                return _buildWorkerCard(
                  context: context,
                  worker: worker,
                  workerData: workerData,
                  priceFormat: priceFormat,
                  isLargeScreen: isLargeScreen,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard({
    required BuildContext context,
    required QueryDocumentSnapshot worker,
    required Map<String, dynamic> workerData,
    required NumberFormat priceFormat,
    required bool isLargeScreen,
  }) {
    final String workerName = workerData['fullName'] ?? 'Unknown';
    final String hourlyRate = priceFormat.format(
        double.tryParse(workerData['hourlyRate'] ?? '0') ?? 0);
    final String experience =
        '${workerData['yearsExperience'] ?? '0'} yrs exp';
    final List<String> skills = (workerData['skills'] as List?)?.cast<String>() ?? [];
    final String imageUrl = workerData['profileImage'] ?? '';
    final double rating = (workerData['rating'] as num?)?.toDouble() ?? 0.0;
    final int completedJobs = workerData['completedJobs'] ?? 0;
    final List<String> languages =
        (workerData['languagesSpoken'] as List?)?.cast<String>() ?? [];
    final bool availableNow = _isWorkerAvailable(workerData);
    final String description = workerData['description'] ?? 'No description provided';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleWorkerViewPage(
              worker: worker,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Container(
                width: isLargeScreen ? 150 : 120,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            
            // Worker Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Experience and Availability
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            experience,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (availableNow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Colors.green, size: 10),
                                SizedBox(width: 4),
                                Text(
                                  'Available Now',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Hourly Rate
                    Text(
                      'Hourly Rate: $hourlyRate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (skills.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skills:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: skills.take(3).map((skill) {
                              return Chip(
                                label: Text(skill),
                                backgroundColor: Colors.grey[100],
                                labelStyle: const TextStyle(fontSize: 12),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    
                  
                    Row(
                      children: [
                        Text(
                          '$completedJobs jobs completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (languages.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                languages.take(1).join(', '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWorkerAvailable(Map<String, dynamic> workerData) {
    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now);
      final currentHour = now.hour;

      final availableDays = workerData['availableDays'] as List? ?? [];
      if (!availableDays.contains(currentDay)) return false;

      final availableHours = workerData['availableHours'] as Map? ?? {};
      final startTime = availableHours['start']?.toString() ?? '9:0';
      final endTime = availableHours['end']?.toString() ?? '17:0';

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final startHour = int.parse(startParts[0]);
      final endHour = int.parse(endParts[0]);

      return currentHour >= startHour && currentHour <= endHour;
    } catch (e) {
      return false;
    }
  }
}
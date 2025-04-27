import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/single_wroker_details_page.dart';

class WorkerSearchScreen extends StatefulWidget {
  @override
  _WorkerSearchScreenState createState() => _WorkerSearchScreenState();
}

class _WorkerSearchScreenState extends State<WorkerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  double _selectedPriceRange = 1000;

  final List<String> _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Carpenter',
    'Cleaner',
    'Painter',
    'AC Technician',
    'Gardener',
    'Mason',
    'Appliance Repair'
  ];

  final List<String> _locations = [
    'All',
    'Kochi',
    'Trivandrum',
    'Kottayam',
    'Bangalore',
    'Chennai',
    'Mumbai',
    'Delhi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Find Service Professionals"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSection(),
          Expanded(
            child: _searchQuery.isEmpty && 
                   _selectedCategory == 'All' && 
                   _selectedLocation == 'All' && 
                   _selectedPriceRange == 1000
                ? _buildWorkerList(FirebaseFirestore.instance.collection('workers').snapshots())
                : FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _searchWorkers(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No professionals found",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                "Try different search criteria",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Apply additional filters
                      List<QueryDocumentSnapshot> filteredResults = snapshot.data!.where((worker) {
                        final data = worker.data() as Map<String, dynamic>;
                        bool categoryMatch = _selectedCategory == 'All' || 
                                            (data['serviceCategory'] ?? '').toLowerCase() == _selectedCategory.toLowerCase();
                        bool locationMatch = _selectedLocation == 'All' || 
                                           ((data['city'] ?? '').toLowerCase().contains(_selectedLocation.toLowerCase()) ||
                                            (data['preferredLocations'] as List?)?.any((loc) => loc.toString().toLowerCase().contains(_selectedLocation.toLowerCase())) == true);
                        bool priceMatch = double.parse(data['hourlyRate'] ?? '0') <= _selectedPriceRange;
                        return categoryMatch && locationMatch && priceMatch;
                      }).toList();
                      
                      if (filteredResults.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_alt_off, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No matching professionals",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                "Adjust your filters",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          var worker = filteredResults[index];
                          return _buildWorkerCard(worker);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search by name, skills, location...",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade800),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Category: $_selectedCategory',
            icon: Icons.category,
            onTap: () => _showCategoryFilter(),
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'Location: $_selectedLocation',
            icon: Icons.location_on,
            onTap: () => _showLocationFilter(),
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'Price: ≤₹$_selectedPriceRange',
            icon: Icons.attach_money,
            onTap: () => _showPriceFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.blue.shade800),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<String>(
                      title: Text(_categories[index]),
                      value: _categories[index],
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<String>(
                      title: Text(_locations[index]),
                      value: _locations[index],
                      groupValue: _selectedLocation,
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Maximum Hourly Rate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "₹${_selectedPriceRange.toInt()}",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
              ),
              Slider(
                value: _selectedPriceRange,
                min: 100,
                max: 2000,
                divisions: 19,
                label: _selectedPriceRange.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriceRange = value;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Apply Filter"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> _searchWorkers(String query) async {
    if (query.isEmpty) {
      QuerySnapshot allResults = await FirebaseFirestore.instance
          .collection('workers')
          .get();
      return allResults.docs;
    }

    QuerySnapshot nameResults = await FirebaseFirestore.instance
        .collection('workers')
        .where('fullName', isGreaterThanOrEqualTo: query)
        .where('fullName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot locationResults = await FirebaseFirestore.instance
        .collection('workers')
        .where('location', isGreaterThanOrEqualTo: query)
        .where('location', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot categoryResults = await FirebaseFirestore.instance
        .collection('workers')
        .where('serviceCategory', isGreaterThanOrEqualTo: query)
        .where('serviceCategory', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot skillResults = await FirebaseFirestore.instance
        .collection('workers')
        .where('skills', arrayContains: query)
        .get();

    Set<String> uniqueIds = {};
    List<QueryDocumentSnapshot> allResults = [];

    for (var snapshot in [nameResults, locationResults, categoryResults, skillResults]) {
      for (var doc in snapshot.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          allResults.add(doc);
        }
      }
    }

    return allResults;
  }

  Widget _buildWorkerList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No service professionals available",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Removed sorting logic
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var worker = snapshot.data!.docs[index];
            return _buildWorkerCard(worker);
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(QueryDocumentSnapshot worker) {
    final workerData = worker.data() as Map<String, dynamic>;
    final rating = workerData['rating'] ?? 0.0;
    final hourlyRate = workerData['hourlyRate'] ?? '0';
    final experience = workerData['yearsExperience'] ?? '0';
    final completedJobs = workerData['completedJobs'] ?? 0;
    final languages = (workerData['languagesSpoken'] as List?)?.join(', ') ?? 'Not specified';
    final skills = (workerData['skills'] as List?)?.take(3).join(', ') ?? 'No skills listed';
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SingleWorkerViewPage(worker: worker),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: workerData['profileImage'] != null
                          ? CachedNetworkImage(
                              imageUrl: workerData['profileImage'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.person, size: 40),
                            )
                          : Icon(Icons.person, size: 40),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Worker Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                workerData['fullName'] ?? 'Unknown Worker',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          workerData['serviceCategory'] ?? 'Service Professional',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                workerData['city'] ?? 'Location not specified',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Skills and Languages
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (skills.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skills,
                        style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                      ),
                    ),
                  if (languages.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        languages,
                        style: TextStyle(color: Colors.purple.shade800, fontSize: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              // Footer with price and experience
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hourly Rate",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "₹$hourlyRate",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Experience",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "$experience yrs",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jobs Done",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "$completedJobs",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "View Profile",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
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
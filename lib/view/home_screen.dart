import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/UserNotificationsPage.dart';
import 'package:on_demant_home_service_app/view/UserNotificationsScreen.dart';
import 'package:on_demant_home_service_app/view/categoryscreen.dart';
import 'package:on_demant_home_service_app/view/single_wroker_details_page.dart';
import 'package:on_demant_home_service_app/view/startup_screen.dart';

class ServiceBookingScreen extends StatelessWidget {
  const ServiceBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ServiceCategory> services = [
      ServiceCategory(
        title: 'Cleaning Services',
        image: 'assets/icons/worker.png',
        category: 'Cleaning Services',
      ),
      ServiceCategory(
        title: 'Beauty Services',
        image: 'assets/icons/makeup.png',
        category: 'Beauty Services',
      ),
      ServiceCategory(
        title: 'Appliance Repairs',
        image: 'assets/icons/appliance-repair.png',
        category: 'Appliance Repairs',
      ),
      ServiceCategory(
        title: 'Laundry Services',
        image: 'assets/icons/laundry.png',
        category: 'Laundry Services',
      ),
      ServiceCategory(
        title: 'Electrician',
        image: 'assets/icons/electrician.png',
        category: 'Electrician',
      ),
      ServiceCategory(
        title: 'Plumber',
        image: 'assets/icons/plumber.png',
        category: 'Plumber',
      ),
      ServiceCategory(
        title: 'AC Service',
        image: 'assets/icons/air-conditioner.png',
        category: 'AC Service',
      ),
      ServiceCategory(
        title: 'Deep Cleaning',
        image: 'assets/icons/time.png',
        category: 'Deep Cleaning',
      ),
      ServiceCategory(
        title: 'Taxi Service',
        image: 'assets/icons/taxi-driver.png',
        category: 'Taxi Service',
      ),
      ServiceCategory(
        title: 'Pick Up & Delivery',
        image: 'assets/icons/delivery-man.png',
        category: 'Pick Up & Delivery',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Home Assist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pacifico',
                  )),
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
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      ' ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => Navigator.push(context, 
                  MaterialPageRoute(builder: (_) => UserNotificationsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, 
                    MaterialPageRoute(builder: (_) => WelcomeScreen()));
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildFeaturedWorkersCarousel(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Our Services",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ServiceCard(service: services[index]),
                childCount: services.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Top Rated Professionals",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('all_works')
                  .orderBy('rating', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()));
                }
                
                final workers = snapshot.data!.docs;
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildWorkerCard(workers[index],context),
                    childCount: workers.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedWorkersCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('all_works')
          .where('rating', isGreaterThan: 4.5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final featuredWorkers = snapshot.data!.docs;
        if (featuredWorkers.isEmpty) return SizedBox.shrink();

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: featuredWorkers.length,
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.8,
                autoPlayInterval: Duration(seconds: 5),),
              itemBuilder: (context, index, realIndex) {
                final worker = featuredWorkers[index];
                return Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.network(
                          worker['coverImage'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker['fullName'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    '${worker['rating']?.toStringAsFixed(1) ?? '5.0'}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Spacer(),
                                  Text(
                                    '₹${worker['hourlyRate']}/h',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildWorkerCard(QueryDocumentSnapshot worker,BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
Navigator.push(context, 
          MaterialPageRoute(builder: (_) => SingleWorkerViewPage(worker: worker)));
        } ,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                worker['coverImage'],
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(worker['profileImage']),
                        radius: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker['fullName'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              worker['serviceCategory'],
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: Colors.blue.shade50,
                        label: Text(
                          '⭐ ${worker['rating']?.toStringAsFixed(1) ?? '5.0'}',
                          style: TextStyle(color: Colors.blue.shade800)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    worker['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (worker['skills'] as List<dynamic>).map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: Colors.grey.shade100,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCategory {
  final String title;
  final String image;
  final String category;

  ServiceCategory({
    required this.title,
    required this.image,
    required this.category,
  });
}

class ServiceCard extends StatelessWidget {
  final ServiceCategory service;
  
  const ServiceCard({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => CategoryWorkersScreen(category: service.category))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                service.image,
                height: 40,
                width: 40,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                service.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blue.shade800,
                ),
                maxLines: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Explore Now →',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:on_demant_home_service_app/view/RegisterWorkDetailsScreen.dart';
import 'package:on_demant_home_service_app/view/WorkerBookingsPage.dart';
import 'package:on_demant_home_service_app/view/WorkerNotificationsScreen.dart';
import 'package:on_demant_home_service_app/view/completedjon.dart';
import 'package:on_demant_home_service_app/view/pendingwork.dart';
import 'package:on_demant_home_service_app/view/startup_screen.dart';
import 'package:on_demant_home_service_app/view/worker_profile.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;


  static  List<Widget> _widgetOptions = <Widget>[
    WorkerBookingsPage(),
    WorkerPendingWorksPage(),
    CompletedJobsScreen(),
    WorkerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterWorkDetailsScreen(),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WorkerNotificationsScreen(),
  ),
);
            },
          ),
        ],
      ),
      drawer: WorkerDrawer(user: user),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}


class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     
          const Row(
            children: [
              Expanded(child: StatCard(title: "Today's Jobs", value: "5", icon: Icons.work)),
              SizedBox(width: 10),
              Expanded(child: StatCard(title: "Pending", value: "3", icon: Icons.pending)),
              SizedBox(width: 10),
              Expanded(child: StatCard(title: "Earnings", value: "\$120", icon: Icons.attach_money)),
            ],
          ),
          const SizedBox(height: 20),
          
     
          const Text(
            'Active Jobs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('workers')
                .where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('status', isEqualTo: 'in-progress')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error loading jobs');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return JobCard(jobData: doc.data() as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
 
          const SizedBox(height: 20),
          const Text(
            'Available Jobs Nearby',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error loading jobs');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return AvailableJobCard(jobData: doc.data() as Map<String, dynamic>);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}


class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


class JobCard extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const JobCard({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  jobData['serviceType'] ?? 'Service',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(jobData['status'] ?? 'Pending'),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${jobData['customerName'] ?? 'N/A'}'),
            Text('Address: ${jobData['address'] ?? 'N/A'}'),
            Text('Scheduled: ${DateFormat('MMM d, y - h:mm a').format((jobData['scheduledTime'] as Timestamp).toDate())}'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
             
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
         
                  },
                  child: const Text('Update Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class AvailableJobCard extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const AvailableJobCard({super.key, required this.jobData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  jobData['serviceType'] ?? 'Service',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Chip(
                  label: Text('Available'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${jobData['customerName'] ?? 'N/A'}'),
            Text('Address: ${jobData['address'] ?? 'N/A'}'),
            Text('Distance: ${jobData['distance'] ?? 'N/A'} km'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
              
                  },
                  child: const Text('Details'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
       
                    FirebaseFirestore.instance
                        .collection('all_works')
                        .doc(jobData['jobId'])
                        .update({
                      'workerId': FirebaseAuth.instance.currentUser?.uid,
                      'status': 'assigned',
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept Job', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class WorkerDrawer extends StatelessWidget {
  final User? user;

  const WorkerDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'Worker'),
            accountEmail: Text(user?.email ?? 'worker@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.displayName?.substring(0, 1) ?? 'W',
                style: const TextStyle(fontSize: 40),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue[800],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('My Schedule'),
            onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => WorkerBookingsPage(),));
            },
          ),
        
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeScreen(),));
            },
          ),
        ],
      ),
    );
  }
}






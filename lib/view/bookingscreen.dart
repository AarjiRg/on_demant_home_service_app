import 'package:flutter/material.dart';

class ElectricianBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: ElectricianBookingScreen(),
    );
  }
}

class ElectricianBookingScreen extends StatefulWidget {
  @override
  _ElectricianBookingScreenState createState() =>
      _ElectricianBookingScreenState();
}

class _ElectricianBookingScreenState extends State<ElectricianBookingScreen> {
  DateTime? selectedDateTime;
  String? selectedAddress;
  TextEditingController requirementController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  bool get isBookingEnabled =>
      selectedDateTime != null && selectedAddress != null;

  void _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _selectAddress() {
    setState(() {
      selectedAddress = "123, Main Street, City";
    });
  }

  void _addWorkingAddress() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Working Address"),
          content: TextField(
            controller: addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter your working address",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedAddress = addressController.text;
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExpandableSection(String title) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text("Details about $title will be displayed here."),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ELECTRICIAN"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🎉 Use code REPAIR75 to get Rs.75 off"),
                  Text("🎉 Use Joboy Reward Coins to Get Rs. 100 Off"),
                ],
              ),
            ),

            SizedBox(height: 16),

            _buildSectionTitle("Service required on"),
            ElevatedButton(
              onPressed: () => _selectDateTime(context),
              child: Text(selectedDateTime == null
                  ? "SELECT DATE & TIME"
                  : "${selectedDateTime!.toLocal()}".split(' ')[0] +
                      " - ${selectedDateTime!.hour}:${selectedDateTime!.minute}"),
            ),

            _buildSectionTitle("Service required at"),
            ElevatedButton(
              onPressed: _selectAddress,
              child: Text(selectedAddress ?? "SELECT ADDRESS"),
            ),

           
            _buildSectionTitle("Add Working Address"),
            ElevatedButton(
              onPressed: _addWorkingAddress,
              child: Text("ADD WORKING ADDRESS"),
            ),

            _buildSectionTitle("SERVICE INFORMATION"),
            TextField(
              controller: requirementController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your requirement",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            Text(
              "* Material charges extra. For work of more than 4 hours, a detailed quote will be given in advance, and work will start on approval.",
            ),
            SizedBox(height: 8),
            Text(
              "* Rs. 150 will be charged if the customer refuses the service after inspection. An additional Rs. 150 will be charged for night services (07:00 PM - 07:00 AM).",
            ),

            Divider(height: 30, thickness: 1),

            _buildExpandableSection("RATE CHART"),
            _buildExpandableSection("TERMS & CONDITIONS"),
            _buildExpandableSection("HOW IT WORKS"),
            _buildExpandableSection("FAQ"),
            _buildExpandableSection("REVIEWS"),

            SizedBox(height: 20),

       
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBookingEnabled ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBookingEnabled
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
                child: Text("CONTINUE BOOKING"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
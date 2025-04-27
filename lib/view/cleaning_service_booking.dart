import 'package:flutter/material.dart';

void main() {
  runApp(CleaningServiceApp());
}

class CleaningServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleaning Service Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ),
      home: CleaningServiceBookingScreen(),
    );
  }
}

class CleaningServiceBookingScreen extends StatefulWidget {
  @override
  _CleaningServiceBookingScreenState createState() =>
      _CleaningServiceBookingScreenState();
}

class _CleaningServiceBookingScreenState
    extends State<CleaningServiceBookingScreen> {
  // List of cleaning types with their respective prices
  final Map<String, double> cleaningTypes = {
    'Basic Cleaning': 50.0,
    'Deep Cleaning': 100.0,
    'Window Cleaning': 30.0,
    'Carpet Cleaning': 70.0,
    'Office Cleaning': 150.0,
  };

  // Selected cleaning types
  List<String> selectedCleaningTypes = [];

  // Total price
  double totalPrice = 0.0;

  // Controller for assigning a note to the selected services
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleaning Service Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for selecting cleaning types
            DropdownButton<String>(
              hint: Text('Select Cleaning Types'),
              isExpanded: true,
              value: null, // No default selection
              items: cleaningTypes.keys.map((String cleaningType) {
                return DropdownMenuItem<String>(
                  value: cleaningType,
                  child: Text(cleaningType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    if (selectedCleaningTypes.contains(newValue)) {
                      // If already selected, remove it
                      selectedCleaningTypes.remove(newValue);
                      totalPrice -= cleaningTypes[newValue]!;
                    } else {
                      // If not selected, add it
                      selectedCleaningTypes.add(newValue);
                      totalPrice += cleaningTypes[newValue]!;
                    }
                  });
                }
              },
            ),
            SizedBox(height: 20),

            // Display selected cleaning types with delete button
            Text(
              'Selected Cleaning Types:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedCleaningTypes.map((cleaningType) {
                return ListTile(
                  title: Text(
                    '- $cleaningType (\$${cleaningTypes[cleaningType]})',
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        selectedCleaningTypes.remove(cleaningType);
                        totalPrice -= cleaningTypes[cleaningType]!;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Text field for assigning a note to the selected services
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Add a note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Display total price
            Text(
              'Total Price: \$${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Confirm Booking Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedCleaningTypes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select at least one cleaning type.')),
                    );
                  } else {
                    // Simulate booking confirmation
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Booking Confirmed'),
                          content: Text(
                              'You have successfully booked the following services:\n\n'
                              '${selectedCleaningTypes.join(', ')}\n\n'
                              'Note: ${_noteController.text}\n\n'
                              'Total Price: \$${totalPrice.toStringAsFixed(2)}'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
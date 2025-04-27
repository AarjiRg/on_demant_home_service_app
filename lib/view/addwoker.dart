import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:on_demant_home_service_app/controller/add_wrokers_controller.dart';
import 'package:on_demant_home_service_app/controller/location_controller.dart';
import 'package:provider/provider.dart';

class AddWorkerScreen extends StatefulWidget {
  @override
  _AddWorkerScreenState createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyPriceController = TextEditingController();
  final TextEditingController _fullDayPriceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _requiredSkillsController = TextEditingController();
  
  final TextEditingController _phnumberController = TextEditingController();

  File? _selectedImage;
  bool isLoading = false;

  List<String> categories = [
    'Cleaning Services',
    'Beauty Services',
    'Appliance Repairs',
    'Laundry Services',
    'Electrician',
    'Plumber',
    'AC Service',
    'Deep Cleaning',
    'Taxi Service'
  ];

  List<String> availabilityOptions = ['Weekdays', 'Weekends', 'Anytime'];
  String? selectedCategory;
  String? selectedAvailability;

  @override
  void initState() {
    super.initState();
    _locationController.addListener(() {
      context
          .read<LocationController>()
          .onStartLocationSearch(_locationController.text);
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitWorker(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      print("No image selected");
      return;
    }

    setState(() => isLoading = true);

    try {
      final addWorkController =
          Provider.of<AddWorkersController>(context, listen: false);
      String? imageUrl = await addWorkController.uploadImg(_selectedImage!);

      if (imageUrl != null) {
        print("Image uploaded successfully: $imageUrl");

        await addWorkController.onAddingNewWorker(
          workerName: _workerNameController.text,
          description: _descriptionController.text,
          hourlyPrice: _hourlyPriceController.text,
          fullDayPrice: _fullDayPriceController.text,
          category: selectedCategory ?? '',
          location: _locationController.text,
          imageUrl: imageUrl,
          availability: selectedAvailability ?? '',
          skills: _skillsController.text,
          notes: _notesController.text,
          requiredSkills: _requiredSkillsController.text,
          phnumber:_phnumberController.text,
          context: context,
        );

        print("Worker data added to Firestore");


        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'isWorker': true,
          });
          print("User profile updated to mark as a worker");
        }
      } else {
        print("Failed to upload image");
      }
    } catch (e) {
      print("Error submitting worker: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit worker: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _descriptionController.dispose();
    _hourlyPriceController.dispose();
    _fullDayPriceController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _notesController.dispose();
    _requiredSkillsController.dispose();
    _phnumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationController>();

    return Scaffold(
      appBar: AppBar(title: Text('Add New Worker')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Worker Name
                TextFormField(
                  controller: _workerNameController,
                  decoration: InputDecoration(labelText: 'Worker Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter worker name' : null,
                ),
                SizedBox(height: 10),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter description' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _phnumberController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'phone number' : null,
                ),
                SizedBox(height: 10),

                // Hourly Price
                TextFormField(
                  controller: _hourlyPriceController,
                  decoration: InputDecoration(labelText: 'Hourly Charge'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter hourly charge' : null,
                ),
                SizedBox(height: 10),

                // Full Day Price
                TextFormField(
                  controller: _fullDayPriceController,
                  decoration: InputDecoration(labelText: 'Full Day Charge'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter full day charge' : null,
                ),
                SizedBox(height: 10),

                // Category Dropdown
                DropdownButtonFormField(
                  decoration: InputDecoration(labelText: 'Category'),
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value as String?;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a category' : null,
                ),
                SizedBox(height: 10),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                      onTap: () {
                        context
                            .read<LocationController>()
                            .onStartLocationSearch(_locationController.text);
                      },
                      child: Icon(Icons.search),
                    ),
                    labelText: "Please select location",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a location" : null,
                ),
                if (locationProvider.startLocationsList.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: locationProvider.isStartLoading
                        ? Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemBuilder: (context, index) => InkWell(
                              onTap: () {
                                String selectedLocation =
                                    locationProvider.startLocationsList[index]
                                        .formattedAddress
                                        .toString();
                                _locationController.text = selectedLocation;
                                locationProvider.clearStartLocations();
                                setState(() {});
                              },
                              child: ListTile(
                                title: Text(locationProvider
                                    .startLocationsList[index]
                                    .formattedAddress
                                    .toString()),
                              ),
                            ),
                            separatorBuilder: (context, index) => Divider(),
                            itemCount: locationProvider.startLocationsList.length,
                          ),
                  ),
                SizedBox(height: 10),

                // Availability Dropdown
                DropdownButtonFormField(
                  decoration: InputDecoration(labelText: 'Availability'),
                  value: selectedAvailability,
                  items: availabilityOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAvailability = value as String?;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select availability' : null,
                ),
                SizedBox(height: 10),

                // Skills
                TextFormField(
                  controller: _skillsController,
                  decoration: InputDecoration(labelText: 'Skills'),
                  validator: (value) => value!.isEmpty ? 'Enter skills' : null,
                ),
                SizedBox(height: 10),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Enter notes' : null,
                ),
                SizedBox(height: 10),

                // Required Skills
                TextFormField(
                  controller: _requiredSkillsController,
                  decoration: InputDecoration(labelText: 'Required Skills'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter required skills' : null,
                ),
                SizedBox(height: 20),

                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImage == null
                        ? Center(child: Text('Tap to select image'))
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 20),

                // Submit Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () => _submitWorker(context),
                        child: Text('Add Worker'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
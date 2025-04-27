import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/location_controller.dart';
import 'package:on_demant_home_service_app/controller/workerregcontoller.dart';
import 'package:provider/provider.dart';

class WorkerRegistrationScreen extends StatefulWidget {
  @override
  _WorkerRegistrationScreenState createState() => _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  List<String> _selectedServices = [];
  final List<String> _availableServices = [
    'Plumber',
    'Deep Cleaning',
    'AC Service',
    'Electrician',
    'Laundry Services',
    'Appliance Repairs',
    'Beauty Services',
    'Cleaning Services'
  ];

  @override
  void initState() {
    super.initState();
    _locationController.addListener(() {
      context.read<LocationController>().onLocationSearch(_locationController.text);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationController>();
    final registrationProvider = context.watch<WorkerRegistrationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Registration'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                SizedBox(height: 10),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _firstNameController,
                        label: 'First Name',
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Invalid phone number';
                    return null;
                  },
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                
                // Professional Information Section
                _buildSectionHeader('Professional Information'),
                SizedBox(height: 10),
                
                Text('Select Your Services', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableServices.map((service) {
                    return FilterChip(
                      label: Text(service),
                      selected: _selectedServices.contains(service),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                      },
                      selectedColor: Colors.blue[200],
                      checkmarkColor: Colors.blue[800],
                    );
                  }).toList(),
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _experienceController,
                  label: 'Years of Experience',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Enter a number';
                    return null;
                  },
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _idNumberController,
                  label: 'Government ID Number',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _hourlyRateController,
                  label: 'Hourly Rate (optional)',
                  keyboardType: TextInputType.number,
                  prefixText: '\$ ',
                ),
                SizedBox(height: 15),
                
                // Location Section
                _buildSectionHeader('Service Area'),
                SizedBox(height: 10),
                
                _buildLocationField(locationProvider),
                SizedBox(height: 15),
                
                // About Section
                _buildSectionHeader('About You'),
                SizedBox(height: 10),
                
                TextFormField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Describe your skills and experience',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 20),
                
                // Account Security Section
                _buildSectionHeader('Account Security'),
                SizedBox(height: 10),
                
                _buildTextFormField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (value.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: 15),
                
                _buildTextFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required';
                    if (value != _passwordController.text) return 'Passwords don\'t match';
                    return null;
                  },
                ),
                SizedBox(height: 30),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: registrationProvider.isLoading
                        ? null
                        : () => _submitRegistration(context),
                    child: registrationProvider.isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('REGISTER AS WORKER', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixText: prefixText,
      ),
    );
  }

  Widget _buildLocationField(LocationController locationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Your service area',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                locationProvider.onStartLocationSearch(_locationController.text);
              },
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
        if (locationProvider.startLocationsList.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            height: 150,
            child: ListView.builder(
              itemCount: locationProvider.startLocationsList.length,
              itemBuilder: (context, index) {
                final location = locationProvider.startLocationsList[index];
                return ListTile(
                  title: Text(location.formattedAddress ?? ''),
                  onTap: () {
                    _locationController.text = location.formattedAddress ?? '';
                    locationProvider.clearStartLocations();
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _submitRegistration(BuildContext context) {
    if (_formKey.currentState!.validate() && _selectedServices.isNotEmpty) {
      context.read<WorkerRegistrationController>().onRegistration(
        emailAddress: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        location: _locationController.text,
        services: _selectedServices,
        experience: _experienceController.text,
        idNumber: _idNumberController.text,
        context: context,
      );
    } else if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one service')),
      );
    }
  }
}
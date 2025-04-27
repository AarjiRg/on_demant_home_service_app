
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/add_addresscontroller.dart';
import 'package:provider/provider.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _roadNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _houseNumberController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _locationController.dispose();
    _phoneNumberController.dispose();
    _roadNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Address"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _fullNameController,
                labelText: "Full Name",
                hintText: "Enter your full name",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your full name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _houseNumberController,
                labelText: "House Number",
                hintText: "Enter your house number",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your house number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _landmarkController,
                labelText: "Landmark",
                hintText: "Enter a nearby landmark",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a landmark";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pincodeController,
                labelText: "Pincode",
                hintText: "Enter your pincode",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your pincode";
                  }
                  if (value.length != 6) {
                    return "Pincode must be 6 digits";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                labelText: "Location",
                hintText: "Enter your location (city/town)",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your location";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneNumberController,
                labelText: "Phone Number",
                hintText: "Enter your phone number",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your phone number";
                  }
                  if (value.length != 10) {
                    return "Phone number must be 10 digits";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _roadNameController,
                labelText: "Road Name",
                hintText: "Enter your road name",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your road name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                     context.read<AddAddresscontroller>().addAddress(
                      fullName: _fullNameController.text, 
                      housenumber:  _houseNumberController.text,
                       landmark:  _landmarkController.text, 
                       pincode:  _pincodeController.text, 
                       location:  _locationController.text,
                        phnumber:  _phoneNumberController.text, 
                        roadname:  _roadNameController.text, 
                        context: context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Save Address",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

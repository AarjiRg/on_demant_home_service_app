import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class RegisterWorkDetailsScreen extends StatefulWidget {
  @override
  _RegisterWorkDetailsScreenState createState() => _RegisterWorkDetailsScreenState();
}

class _RegisterWorkDetailsScreenState extends State<RegisterWorkDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  File? _profileImage;

  final TextEditingController _aboutMeController = TextEditingController();
  List<String> _selectedLanguages = [];
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();

  String? _selectedIdType;
  final TextEditingController _idNumberController = TextEditingController();
  File? _idProofImage;

  List<String> _selectedWorkDays = [];
  TimeOfDay? _startWorkTime;
  TimeOfDay? _endWorkTime;
  List<String> _selectedWorkLocations = [];
  bool _willingToWorkOnHolidays = false;

  String? _selectedServiceCategory;
  List<String> _selectedSkills = [];
  final TextEditingController _yearsExperienceController = TextEditingController();
  File? _workCertification;
  List<File> _previousWorkImages = [];
  final TextEditingController _hourlyRateController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _coverImage;
  List<File> _workImages = [];
  
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _languageOptions = ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Gujarati', 'Punjabi'];
  final List<String> _idTypeOptions = ['Aadhaar', 'Passport', 'Driver License', 'PAN Card', 'Voter ID'];
  final List<String> _workDayOptions = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _serviceCategoryOptions = [
    'Plumber',
    'Deep Cleaning',
    'AC Service',
    'Electrician',
    'Laundry Services',
    'Appliance Repairs',
    'Beauty Services',
    'Cleaning Services'
  ];
  final Map<String, List<String>> _serviceSkills = {
    'Plumber': ['Pipe Fitting', 'Leak Repair', 'Bathroom Installation', 'Water Heater Installation'],
    'Deep Cleaning': ['House Cleaning', 'Office Cleaning', 'Post Construction', 'Carpet Cleaning'],
    'AC Service': ['AC Installation', 'AC Repair', 'Gas Charging', 'Maintenance'],
    'Electrician': ['Wiring', 'Switch Repair', 'Light Installation', 'DB Box Repair'],
    'Laundry Services': ['Wash & Iron', 'Dry Cleaning', 'Steam Press', 'Stain Removal'],
    'Appliance Repairs': ['Refrigerator', 'Washing Machine', 'Microwave', 'Mixer'],
    'Beauty Services': ['Haircut', 'Facial', 'Manicure', 'Pedicure'],
    'Cleaning Services': ['Housekeeping', 'Utensil Cleaning', 'Bathroom Cleaning', 'Window Cleaning']
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isProfile = false, bool isIdProof = false, bool isCertification = false}) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else if (isIdProof) {
          _idProofImage = File(pickedFile.path);
        } else if (isCertification) {
          _workCertification = File(pickedFile.path);
        } else {
          _coverImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _pickWorkImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _workImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _pickPreviousWorkImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _previousWorkImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index, {bool isWorkImage = false, bool isPreviousWorkImage = false}) {
    setState(() {
      if (isWorkImage) {
        _workImages.removeAt(index);
      } else if (isPreviousWorkImage) {
        _previousWorkImages.removeAt(index);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {bool isStartTime = true}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startWorkTime = picked;
        } else {
          _endWorkTime = picked;
        }
      });
    }
  }

  Future<String> _uploadImage(File image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  Future<void> _saveWorkDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null || _idProofImage == null || _coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload required images')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final profileImageUrl = await _uploadImage(
        _profileImage!,
        'users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final idProofUrl = await _uploadImage(
        _idProofImage!,
        'users/${user.uid}/id_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final coverImageUrl = await _uploadImage(
        _coverImage!,
        'works/${user.uid}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      List<String> workImageUrls = [];
      for (var image in _workImages) {
        final url = await _uploadImage(
          image,
          'works/${user.uid}/work_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        workImageUrls.add(url);
      }

      List<String> previousWorkImageUrls = [];
      for (var image in _previousWorkImages) {
        final url = await _uploadImage(
          image,
          'works/${user.uid}/previous_work_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        previousWorkImageUrls.add(url);
      }

      String? certificationUrl;
      if (_workCertification != null) {
        certificationUrl = await _uploadImage(
          _workCertification!,
          'works/${user.uid}/certification_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final workerData = {
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'profileImage': profileImageUrl,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'country': _countryController.text,
        'aboutMe': _aboutMeController.text,
        'languagesSpoken': _selectedLanguages,
        'emergencyContact': {
          'name': _emergencyContactNameController.text,
          'number': _emergencyContactNumberController.text,
        },
        'additionalNotes': _additionalNotesController.text,
        'idType': _selectedIdType,
        'idNumber': _idNumberController.text,
        'idProof': idProofUrl,
        'availableDays': _selectedWorkDays,
        'availableHours': {
          'start': _startWorkTime != null ? '${_startWorkTime!.hour}:${_startWorkTime!.minute}' : null,
          'end': _endWorkTime != null ? '${_endWorkTime!.hour}:${_endWorkTime!.minute}' : null,
        },
        'preferredLocations': _selectedWorkLocations,
        'workOnHolidays': _willingToWorkOnHolidays,
        
        'serviceCategory': _selectedServiceCategory,
        'skills': _selectedSkills,
        'yearsExperience': _yearsExperienceController.text,
        'certification': certificationUrl,
        'previousWorkImages': previousWorkImageUrls,
        'hourlyRate': _hourlyRateController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'coverImage': coverImageUrl,
        'workImages': workImageUrls,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active', 
        'rating': 0,
        'completedJobs': 0,
      };

      final firestore = FirebaseFirestore.instance;

      await firestore.collection('workers').doc(user.uid).set(workerData);
      
     
 
      
      final allWorksRef = await firestore.collection('all_works').add(workerData);
      
      await firestore
          .collection('workers')
          .doc(user.uid)
          .collection('my_works')
          .doc(allWorksRef.id)
          .set(workerData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile and work details saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          
              _buildSectionHeader('1. Personal Information'),
              _buildProfileImageUpload(),
              SizedBox(height: 16),
              _buildTextFormField(_fullNameController, 'Full Name', isRequired: true),
              _buildTextFormField(_phoneController, 'Phone Number', isRequired: true, keyboardType: TextInputType.phone),
              _buildTextFormField(_emailController, 'Email Address', isRequired: true, keyboardType: TextInputType.emailAddress, enabled: false),
              _buildDatePickerField(_dobController, 'Date of Birth'),
              _buildTextFormField(_genderController, 'Gender', isRequired: true, hint: 'Male/Female/Other'),
              _buildTextFormField(_addressController, 'Address', isRequired: true, maxLines: 2),
              _buildTextFormField(_cityController, 'City', isRequired: true),
              _buildTextFormField(_stateController, 'State', isRequired: true),
              _buildTextFormField(_pincodeController, 'Pincode', isRequired: true, keyboardType: TextInputType.number),
              _buildTextFormField(_countryController, 'Country', isRequired: true),
              _buildSectionHeader('2. About Me'),
              _buildTextFormField(_aboutMeController, 'Short Description', maxLines: 3, hint: 'Tell us about yourself'),
              SizedBox(height: 16),
              _buildMultiSelectDropdown('Languages Spoken', _languageOptions, _selectedLanguages),
              SizedBox(height: 16),
              _buildTextFormField(_emergencyContactNameController, 'Emergency Contact Name'),
              _buildTextFormField(_emergencyContactNumberController, 'Emergency Contact Number', keyboardType: TextInputType.phone),
              _buildTextFormField(_additionalNotesController, 'Additional Notes (Optional)', maxLines: 2),  
              _buildSectionHeader('3. Government ID'),
              _buildDropdown(_idTypeOptions, _selectedIdType, 'Select ID Type', (value) {
                setState(() {
                  _selectedIdType = value;
                });
              }, isRequired: true),
              SizedBox(height: 16),
              _buildTextFormField(_idNumberController, 'ID Number', isRequired: true),
              SizedBox(height: 8),
              Text('Upload ID Proof', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildImageUploadButton(() => _pickImage(ImageSource.gallery, isIdProof: true), _idProofImage, 'ID Proof'),
              
         
              _buildSectionHeader('4. Availability & Work Preferences'),
              _buildMultiSelectDropdown('Available Work Days', _workDayOptions, _selectedWorkDays),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField('Start Time', _startWorkTime, () => _selectTime(context, isStartTime: true)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePickerField('End Time', _endWorkTime, () => _selectTime(context, isStartTime: false)),
                  ),
                ],
              ),
              SizedBox(height: 16),
             LocationSearchField(
  initialLocations: _selectedWorkLocations,
  onLocationsSelected: (locations) {
    setState(() {
      _selectedWorkLocations = locations;
    });
  },
),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Willing to Work on Holidays?', style: TextStyle(fontSize: 16)),
                  Spacer(),
                  Switch(
                    value: _willingToWorkOnHolidays,
                    onChanged: (value) {
                      setState(() {
                        _willingToWorkOnHolidays = value;
                      });
                    },
                  ),
                ],
              ),
              
            
              _buildSectionHeader('5. Service Details'),
              _buildDropdown(_serviceCategoryOptions, _selectedServiceCategory, 'Service Category', (value) {
                setState(() {
                  _selectedServiceCategory = value;
                  _selectedSkills = []; 
                });
              }, isRequired: true),
              SizedBox(height: 16),
              if (_selectedServiceCategory != null && _serviceSkills.containsKey(_selectedServiceCategory))
                _buildMultiSelectDropdown(
                  'Specialized Skills', 
                  _serviceSkills[_selectedServiceCategory]!, 
                  _selectedSkills,
                ),
              SizedBox(height: 16),
              _buildTextFormField(_yearsExperienceController, 'Years of Experience', keyboardType: TextInputType.number),
              SizedBox(height: 16),
              Text('Work Certification (if applicable)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildImageUploadButton(() => _pickImage(ImageSource.gallery, isCertification: true), _workCertification, 'Certification'),
              SizedBox(height: 16),
              Text('Previous Work Images (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildImageGrid(_previousWorkImages, isPreviousWorkImage: true),
              OutlinedButton(
                onPressed: _pickPreviousWorkImages,
                child: Text('Add Previous Work Images'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
              SizedBox(height: 16),
              _buildTextFormField(_hourlyRateController, 'Expected Hourly Rate / Service Rate', keyboardType: TextInputType.number, prefix: Text('₹ ')),
              
           
              _buildSectionHeader('6. Work Details'),
              Text('Cover Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildImageUploadButton(() => _pickImage(ImageSource.gallery), _coverImage, 'Cover Photo'),
              SizedBox(height: 16),
              _buildTextFormField(_titleController, 'Work Title', isRequired: true),
              _buildTextFormField(_descriptionController, 'Work Description', maxLines: 4),
              SizedBox(height: 16),
              Text('Work Images (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildImageGrid(_workImages),
              OutlinedButton(
                onPressed: _pickWorkImages,
                child: Text('Add Work Images'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
              
           
              SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveWorkDetails,
                      child: Text('Save All Details'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller, 
    String label, {
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    ValueChanged<String>? onChanged,
    Widget? prefix,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          border: OutlineInputBorder(),
          hintText: hint,
          prefix: prefix,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        } : null,
        onChanged: onChanged,
        enabled: enabled,
      ),
    );
  }

  Widget _buildDatePickerField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () => _selectDate(context),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$label *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(time != null ? time.format(context) : 'Select $label'),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? selectedValue, String hint, ValueChanged<String?> onChanged, {bool isRequired = false}) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: '$hint${isRequired ? ' *' : ''}',
        border: OutlineInputBorder(),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $hint';
        }
        return null;
      } : null,
    );
  }

  Widget _buildMultiSelectDropdown(String title, List<String> options, List<String> selectedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedItems.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedItems.add(option);
                  } else {
                    selectedItems.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (selectedItems.isEmpty)
          Text('Please select at least one option', style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Picture *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery, isProfile: true),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null 
                  ? Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        if (_profileImage == null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Please upload a profile picture', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildImageUploadButton(VoidCallback onPressed, File? image, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: onPressed,
          child: Text('Upload $label'),
          style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
        if(image != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('$label uploaded', style: TextStyle(color: Colors.green)),
          ),
      
      ],
    );
  }

  Widget _buildImageGrid(List<File> images, {bool isPreviousWorkImage = false}) {
    if (images.isEmpty) return SizedBox();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeImage(index, 
                  isWorkImage: !isPreviousWorkImage, 
                  isPreviousWorkImage: isPreviousWorkImage),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _aboutMeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _additionalNotesController.dispose();
    _idNumberController.dispose();
    _yearsExperienceController.dispose();
    _hourlyRateController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
}
class LocationSearchField extends StatefulWidget {
  final ValueChanged<List<String>> onLocationsSelected;
  final List<String> initialLocations;

  const LocationSearchField({
    required this.onLocationsSelected,
    this.initialLocations = const [],
    Key? key,
  }) : super(key: key);

  @override
  _LocationSearchFieldState createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedLocations = [];
  List<String> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedLocations = widget.initialLocations;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=AIzaSyCX6jheIEuMGvB_dG17OVw81bX0KWSf__k&components=country:in',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions = (data['predictions'] as List)
              .map((prediction) => prediction['description'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  void _addLocation(String location) {
    if (!_selectedLocations.contains(location)) {
      setState(() {
        _selectedLocations.add(location);
        _searchController.clear();
        _suggestions = [];
      });
      widget.onLocationsSelected(_selectedLocations);
    }
  }

  void _removeLocation(String location) {
    setState(() {
      _selectedLocations.remove(location);
    });
    widget.onLocationsSelected(_selectedLocations);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Work Locations *', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search locations...',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_suggestions[index]),
                  onTap: () => _addLocation(_suggestions[index]),
                );
              },
            ),
          ),
        if (_selectedLocations.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedLocations.map((location) => Chip(
                label: Text(location),
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () => _removeLocation(location),
              )).toList(),
            ),
          ),
        if (_selectedLocations.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Please select at least one location', 
              style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}
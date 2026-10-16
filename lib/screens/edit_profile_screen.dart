// edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthdayController;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _usernameController = TextEditingController(text: user?['username'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _firstNameController = TextEditingController(
      text: user?['first_name'] ?? '',
    );
    _lastNameController = TextEditingController(text: user?['last_name'] ?? '');
    _birthdayController = TextEditingController(
      text: user?['birthy_day'] ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // Function to format date to YYYY-MM-DD
  String _formatDate(String date) {
    try {
      if (date.isEmpty) return '';

      // If date is already in correct format
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        return date;
      }

      // Try to convert from DD/MM/YYYY
      if (date.contains('/')) {
        final parts = date.split('/');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY/MM/DD
            return "${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}";
          } else {
            // DD/MM/YYYY
            return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
          }
        }
      }

      // Try to convert from YYYY-MM-DD
      if (date.contains('-') && date.length == 10) {
        return date;
      }

      return date;
    } catch (e) {
      print('Error formatting date: $e');
      return date;
    }
  }

  // Date picker
  Future<void> _selectDate() async {
    DateTime initialDate;

    try {
      if (_birthdayController.text.isNotEmpty) {
        final parts = _birthdayController.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          initialDate = DateTime.now();
        }
      } else {
        initialDate = DateTime.now();
      }
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Check if there are real changes
  bool _hasRealChanges() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // Check if data is different from current data
    bool usernameChanged =
        _usernameController.text.isNotEmpty &&
        _usernameController.text != (user?['username'] ?? '');

    bool emailChanged =
        _emailController.text.isNotEmpty &&
        _emailController.text != (user?['email'] ?? '');

    bool firstNameChanged =
        _firstNameController.text.isNotEmpty &&
        _firstNameController.text != (user?['first_name'] ?? '');

    bool lastNameChanged =
        _lastNameController.text.isNotEmpty &&
        _lastNameController.text != (user?['last_name'] ?? '');

    bool birthdayChanged =
        _birthdayController.text.isNotEmpty &&
        _birthdayController.text != (user?['birthy_day'] ?? '');

    bool photoChanged = _selectedImage != null;

    return usernameChanged ||
        emailChanged ||
        firstNameChanged ||
        lastNameChanged ||
        birthdayChanged ||
        photoChanged;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Check if there are changes
      if (!_hasRealChanges()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('You haven\'t made any changes')),
              ],
            ),
            backgroundColor: Colors.orange.shade50,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      try {
        // Format date before sending
        String? formattedBirthday;
        if (_birthdayController.text.isNotEmpty) {
          formattedBirthday = _formatDate(_birthdayController.text);

          // Check date format after formatting
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(formattedBirthday)) {
            throw Exception('Invalid date format. Use YYYY-MM-DD');
          }
        }

        // Send only changed data
        bool success = await authProvider.updateProfile(
          username:
              _usernameController.text.isNotEmpty &&
                  _usernameController.text != currentUser?['username']
              ? _usernameController.text
              : null,
          email:
              _emailController.text.isNotEmpty &&
                  _emailController.text != currentUser?['email']
              ? _emailController.text
              : null,
          firstName:
              _firstNameController.text.isNotEmpty &&
                  _firstNameController.text != currentUser?['first_name']
              ? _firstNameController.text
              : null,
          lastName:
              _lastNameController.text.isNotEmpty &&
                  _lastNameController.text != currentUser?['last_name']
              ? _lastNameController.text
              : null,
          birthday:
              formattedBirthday != null &&
                  formattedBirthday != currentUser?['birthy_day']
              ? formattedBirthday
              : null,
          photo: _selectedImage,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Profile updated successfully!')),
                ],
              ),
              backgroundColor: Colors.green.shade50,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          await authProvider.refreshUserData();

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        String errorMessage = e.toString();

        // Clean up error message
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade50,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose image source'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.green.shade700),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_camera, color: Colors.green.shade700),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text(
          'Are you sure you want to remove your profile picture?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Image removed')),
                    ],
                  ),
                  backgroundColor: Colors.green.shade50,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    bool hasChanges =
        _usernameController.text != (user?['username'] ?? '') ||
        _emailController.text != (user?['email'] ?? '') ||
        _firstNameController.text != (user?['first_name'] ?? '') ||
        _lastNameController.text != (user?['last_name'] ?? '') ||
        _birthdayController.text != (user?['birthy_day'] ?? '') ||
        _selectedImage != null;

    if (hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final hasExistingPhoto =
        user?['photo'] != null && user!['photo'].isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.teal.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showDiscardDialog,
            tooltip: 'Back',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade700,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Updating profile...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade50, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile picture section with green theme
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.shade200.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.green.shade100,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (hasExistingPhoto
                                              ? NetworkImage(user!['photo'])
                                              : null)
                                          as ImageProvider?,
                                child:
                                    _selectedImage == null && !hasExistingPhoto
                                    ? Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.green.shade700,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade300,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  onSelected: (String value) {
                                    if (value == 'gallery') {
                                      _pickImage(ImageSource.gallery);
                                    } else if (value == 'camera') {
                                      _pickImage(ImageSource.camera);
                                    } else if (value == 'remove') {
                                      _showRemoveImageDialog();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'gallery',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.photo_library,
                                              color: Colors.green.shade700,
                                            ),
                                            title: const Text('Gallery'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'camera',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.photo_camera,
                                              color: Colors.green.shade700,
                                            ),
                                            title: const Text('Camera'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        if (_selectedImage != null ||
                                            hasExistingPhoto)
                                          PopupMenuItem<String>(
                                            value: 'remove',
                                            child: ListTile(
                                              leading: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              title: const Text(
                                                'Remove image',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                      ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form fields with green theme
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.badge,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.badge_outlined,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        color: Colors.blue,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Date field with date picker
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _birthdayController,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: InputDecoration(
                            labelText: 'Birth Date',
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.cake,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: Colors.orange.shade700,
                              ),
                              onPressed: _selectDate,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'YYYY-MM-DD',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(
                                r'^\d{4}-\d{2}-\d{2}$',
                              ).hasMatch(value)) {
                                return 'Use format YYYY-MM-DD';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons with green theme
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _firstNameController.text =
                                      user?['first_name'] ?? '';
                                  _lastNameController.text =
                                      user?['last_name'] ?? '';
                                  _usernameController.text =
                                      user?['username'] ?? '';
                                  _emailController.text = user?['email'] ?? '';
                                  _birthdayController.text =
                                      user?['birthy_day'] ?? '';
                                  _selectedImage = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text('Form reset completed'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade50,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.green.shade700,
                              ),
                              label: Text(
                                'Reset',
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 55),
                                side: BorderSide(color: Colors.green.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showDiscardDialog,
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                              ),
                              label: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 55),
                                side: BorderSide(color: Colors.red.shade200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Save button with gradient
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade700,
                              Colors.teal.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method to build text fields with consistent green theme
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required MaterialColor color,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.shade700, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value != null && value.isEmpty && label == 'Email') {
            return 'Please enter your email';
          }
          return null;
        },
      ),
    );
  }
}

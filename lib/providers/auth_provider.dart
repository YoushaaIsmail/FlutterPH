// auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoadingProfile = false;
  String? _profileError;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  // ✅ Get specific user details with formatted output
  Map<String, dynamic> getUserDetails() {
    if (_user == null) {
      return {};
    }

    return {
      'id': _user?['id'] ?? _user?['user_id'] ?? 'N/A',
      'username': _user?['username'] ?? 'N/A',
      'email': _user?['email'] ?? 'N/A',
      'firstName': _user?['first_name'] ?? _user?['firstName'] ?? 'N/A',
      'lastName': _user?['last_name'] ?? _user?['lastName'] ?? 'N/A',
      'fullName': _getFullName(),
      'birthday': _user?['birthy_day'] ?? _user?['birthday'] ?? 'N/A',
      'phone': _user?['phone'] ?? _user?['phone_number'] ?? 'N/A',
      'photo': _user?['photo'] ?? _user?['profile_picture'] ?? null,
      'joinDate': _user?['date_joined'] ?? _user?['created_at'] ?? 'N/A',
      'isActive': _user?['is_active'] ?? true,
      'isStaff': _user?['is_staff'] ?? false,
    };
  }

  // ✅ Helper method to get full name
  String _getFullName() {
    String firstName = _user?['first_name'] ?? '';
    String lastName = _user?['last_name'] ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return 'N/A';
  }

  int get userId {
    final userId = _user?['id'] ?? _user?['user_id'];
    if (userId is int) return userId;
    if (userId is String) return int.tryParse(userId) ?? 0;
    return 0;
  }

  // ✅ Get user's display name
  String getDisplayName() {
    if (_user == null) return 'User';

    String fullName = _getFullName();
    if (fullName != 'N/A') return fullName;

    String username = _user?['username'] ?? '';
    if (username.isNotEmpty) return username;

    String email = _user?['email'] ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  // ✅ Get user's initials for avatar
  String getUserInitials() {
    if (_user == null) return 'U';

    String firstName = _user?['first_name'] ?? '';
    String lastName = _user?['last_name'] ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else {
      String username = _user?['username'] ?? '';
      if (username.isNotEmpty) {
        return username[0].toUpperCase();
      }
    }
    return 'U';
  }

  // ✅ Get user profile photo URL
  String? getUserPhotoUrl() {
    String? photoPath = _user?['photo'];
    if (photoPath != null && photoPath.isNotEmpty) {
      // Check if it's a full URL or relative path
      if (photoPath.startsWith('http')) {
        return photoPath;
      } else {
        // Construct full URL from base URL
        return '${ApiService.baseUrl}$photoPath';
      }
    }
    return null;
  }

  // ✅ Get formatted birthday
  String getFormattedBirthday() {
    String birthday = _user?['birthy_day'] ?? _user?['birthday'] ?? '';
    if (birthday.isEmpty || birthday == 'N/A') return 'Not set';

    try {
      // Try to parse and format the date
      DateTime date = DateTime.parse(birthday);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return birthday;
    }
  }

  // ✅ Get user age from birthday
  int? getUserAge() {
    String birthday = _user?['birthy_day'] ?? _user?['birthday'] ?? '';
    if (birthday.isEmpty || birthday == 'N/A') return null;

    try {
      DateTime birthDate = DateTime.parse(birthday);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // ✅ Get profile completion percentage
  double getProfileCompletionPercentage() {
    if (_user == null) return 0.0;

    List<String> fields = [
      'first_name',
      'last_name',
      'email',
      'phone',
      'birthy_day',
    ];

    int filledFields = 0;
    for (String field in fields) {
      var value = _user?[field];
      if (value != null && value.toString().isNotEmpty && value != 'null') {
        filledFields++;
      }
    }

    return (filledFields / fields.length) * 100;
  }

  // ✅ Check if profile is complete
  bool isProfileComplete() {
    return getProfileCompletionPercentage() == 100;
  }

  // ✅ Get list of missing profile fields
  List<String> getMissingProfileFields() {
    if (_user == null) return [];

    List<String> missingFields = [];
    Map<String, String> fieldNames = {
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'phone': 'Phone Number',
      'birthy_day': 'Birth Date',
    };

    fieldNames.forEach((field, displayName) {
      var value = _user?[field];
      if (value == null || value.toString().isEmpty || value == 'null') {
        missingFields.add(displayName);
      }
    });

    return missingFields;
  }

  // ✅ Check authentication status
  Future<void> checkAuthStatus() async {
    print('\n🔍 Checking authentication status...');
    _token = await ApiService.getToken();
    print('🔑 Retrieved token from SharedPreferences: $_token');

    if (_token != null) {
      await refreshUserData();
    } else {
      print('⚠️ No token stored');
    }
  }

  // ✅ Login using ApiService
  Future<bool> login(String username, String password) async {
    try {
      print('\n========== Starting Login ==========');
      print('👤 Username: $username');

      final response = await ApiService.login(username, password);

      // Print full response for debugging
      print('📦 Server response:');
      print('📄 Content: $response');
      print('🔑 Response keys: ${response.keys}');

      // ✅ Find token in different locations
      String? token;

      if (response.containsKey('token')) {
        token = response['token'];
        print('✅ Found token in key "token"');
      } else if (response.containsKey('key')) {
        token = response['key'];
        print('✅ Found token in key "key"');
      } else if (response.containsKey('access')) {
        token = response['access'];
        print('✅ Found token in key "access"');
      } else if (response.containsKey('access_token')) {
        token = response['access_token'];
        print('✅ Found token in key "access_token"');
      }

      if (token != null) {
        // Store token
        _token = token;
        print('🔑 Extracted token: $_token');

        // ✅ Find user data
        if (response.containsKey('user')) {
          _user = response['user'];
          print('✅ Found user in key "user"');
        } else if (response.containsKey('profile')) {
          _user = response['profile'];
          print('✅ Found user in key "profile"');
        } else if (response.containsKey('data')) {
          _user = response['data'];
          print('✅ Found user in key "data"');
        } else {
          // If no specific key, use full response
          _user = response;
          print('⚠️ No specific user key found, using full response');
        }

        // Save token to SharedPreferences
        await ApiService.saveToken(_token!);

        // Verify save
        final savedToken = await ApiService.getToken();
        print('💾 Saved token in SharedPreferences: $savedToken');

        if (savedToken == _token) {
          print('✅ Token saved successfully');
        } else {
          print('❌ Failed to save token');
        }

        // Fetch full profile data including birth date and image using ApiService
        await refreshUserData();

        print('✅ Login successful');
        print('👤 Final user data: $_user');
        print('=====================================\n');

        notifyListeners();
        return true;
      } else {
        print('❌ No token found in response');
        print('📄 Full response: $response');
        print('=====================================\n');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      print('=====================================\n');
      return false;
    }
  }

  // ✅ Fetch user profile using ApiService (including birth date and image)
  Future<bool> fetchUserProfile() async {
    try {
      if (_token == null) {
        print('⚠️ No token available');
        return false;
      }

      print('\n📡 Fetching user profile using ApiService...');

      // Use the ApiService method instead of direct HTTP call
      final userData = await ApiService.fetchUserProfile();

      // Merge with existing user data
      _user = {...?_user, ...userData};

      print('✅ User profile fetched successfully');
      print('👤 User data: $_user');
      print('🎂 Birth date: ${getFormattedBirthday()}');
      print('📸 Photo: ${getUserPhotoUrl()}');

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return false;
    }
  }

  // ✅ Refresh user data from server using both endpoints if needed
  Future<bool> refreshUserData() async {
    try {
      _isLoadingProfile = true;
      _profileError = null;
      // notifyListeners();

      print('\n📡 Refreshing user data...');

      if (_token == null) {
        print('⚠️ No token, attempting to retrieve...');
        _token = await ApiService.getToken();
        if (_token == null) {
          print('❌ Cannot refresh - no token available');
          _profileError = 'No active session';
          _isLoadingProfile = false;
          notifyListeners();
          return false;
        }
      }

      // First try to fetch detailed user profile from user endpoint
      bool success = false;
      try {
        success = await fetchUserProfile();
        if (success) {
          print('✅ Successfully fetched detailed user profile');
        }
      } catch (e) {
        print(
          '⚠️ Failed to fetch from user endpoint, trying profile endpoint...',
        );
      }

      // If detailed profile fetch failed, fall back to basic profile endpoint
      if (!success) {
        try {
          print('📡 Falling back to basic profile endpoint...');
          final profileData = await ApiService.fetchProfile();
          _user = {...?_user, ...profileData};
          success = true;
          print('✅ Successfully fetched basic profile data');
        } catch (e) {
          print('❌ Failed to fetch from both endpoints: $e');
          _profileError = e.toString();
          success = false;
        }
      }

      _isLoadingProfile = false;
      notifyListeners();

      return success;
    } catch (e) {
      print('❌ Error refreshing user data: $e');
      _profileError = e.toString();
      _isLoadingProfile = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Update profile (including image)
  Future<bool> updateProfile({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? birthday,
    File? photo,
  }) async {
    try {
      print('\n========== Updating Profile ==========');

      if (_token == null) {
        print('❌ Error: Token not found');
        return false;
      }

      print('🔑 Token used: $_token');

      var uri = Uri.parse(
        '${ApiService.baseUrl}/user/api/user/edit-profile-serializer/',
      );

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Token $_token';
      request.headers['Accept'] = 'application/json';

      // Add fields only if they are different from current data
      bool hasChanges = false;

      if (username != null &&
          username.isNotEmpty &&
          username != _user?['username']) {
        request.fields['username'] = username;
        hasChanges = true;
        print('📧 Changing username to: $username');
      }

      if (email != null && email.isNotEmpty && email != _user?['email']) {
        request.fields['email'] = email;
        hasChanges = true;
        print('📧 Changing email to: $email');
      }

      if (firstName != null &&
          firstName.isNotEmpty &&
          firstName != _user?['first_name']) {
        request.fields['first_name'] = firstName;
        hasChanges = true;
        print('👤 Changing first_name to: $firstName');
      }

      if (lastName != null &&
          lastName.isNotEmpty &&
          lastName != _user?['last_name']) {
        request.fields['last_name'] = lastName;
        hasChanges = true;
        print('👤 Changing last_name to: $lastName');
      }

      if (birthday != null &&
          birthday.isNotEmpty &&
          birthday != _user?['birthy_day']) {
        // Validate date format
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthday)) {
          request.fields['birthy_day'] = birthday;
          hasChanges = true;
          print('🎂 Changing birthy_day to: $birthday');
        } else {
          print('❌ Invalid date format: $birthday');
          throw Exception('Invalid date format. Use YYYY-MM-DD');
        }
      }

      if (photo != null) {
        var file = await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          filename: photo.path.split('/').last,
        );
        request.files.add(file);
        hasChanges = true;
        print('🖼️ Changing photo');
      }

      if (!hasChanges) {
        print('⚠️ No changes detected');
        return true;
      }

      print('📦 Sending request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['user'] != null) {
          _user = responseData['user'];
        }

        // Refresh full profile data using ApiService
        await refreshUserData();

        notifyListeners();
        print('✅ Profile updated successfully');
        return true;
      } else if (response.statusCode == 400) {
        var errors = json.decode(response.body);
        print('❌ Validation errors: $errors');

        // Convert errors to readable message
        String errorMessage = '';
        errors.forEach((key, value) {
          if (value is List) {
            errorMessage += '${_getFieldName(key)}: ${value.join(', ')}\n';
          }
        });

        throw Exception(errorMessage.trim());
      } else {
        throw Exception('Update failed (${response.statusCode})');
      }
    } catch (e) {
      print('🔥 Error: $e');
      rethrow;
    }
  }

  // Helper method to translate field names
  String _getFieldName(String field) {
    switch (field) {
      case 'username':
        return 'Username';
      case 'email':
        return 'Email';
      case 'first_name':
        return 'First Name';
      case 'last_name':
        return 'Last Name';
      case 'birthy_day':
        return 'Birth Date';
      default:
        return field;
    }
  }

  // ✅ Debug helper function
  Future<void> debugAuthState() async {
    print('\n========== Authentication State Debug ==========');
    print('🔑 Token in memory: $_token');
    print('👤 User in memory: $_user');

    final savedToken = await ApiService.getToken();
    print('💾 Token in SharedPreferences: $savedToken');

    if (_token != null && savedToken != null) {
      print('✅ Token match: ${_token == savedToken}');
    } else if (_token == null && savedToken != null) {
      print('⚠️ Token exists in SharedPreferences but not in memory');
      _token = savedToken;
      print('✅ Token restored from SharedPreferences');
    } else if (_token != null && savedToken == null) {
      print('⚠️ Token exists in memory but not in SharedPreferences');
      await ApiService.saveToken(_token!);
      print('✅ Token saved to SharedPreferences');
    } else {
      print('❌ No token found anywhere');
    }

    print('========================================\n');
  }

  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  // ✅ Logout
  Future<void> logout() async {
    print('\n👋 Logging out...');
    await ApiService.logout();
    _user = null;
    _token = null;
    _profileError = null;
    _isLoadingProfile = false;
    notifyListeners();
    print('✅ Logout successful');
  }

  // ✅ Registration
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('\n📝 Attempting registration...');
      print('👤 Username: $username');
      print('📧 Email: $email');

      await ApiService.register(username, email, password);

      print('✅ Registration successful');
      return true;
    } catch (e) {
      print('❌ Registration error: $e');
      return false;
    }
  }

  // ✅ OTP verification
  Future<bool> verifyOtp(String email, String code) async {
    try {
      print('\n📝 Verifying OTP...');
      print('📧 Email: $email');
      print('🔢 Code: $code');

      await ApiService.verifyOtp(email, code);

      print('✅ Verification successful');
      return true;
    } catch (e) {
      print('❌ Verification error: $e');
      return false;
    }
  }
}

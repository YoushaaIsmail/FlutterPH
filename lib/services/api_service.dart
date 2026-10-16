import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class ApiService {
  // Use a common base URL – adjust if needed (e.g., 10.0.2.2 for Android emulator)
  static const String baseUrl =
      "http://192.168.137.1:8000"; // your Django backend
  static const String userProfileEndpoint = "$baseUrl/user/user/";
  // Existing medicine endpoints
  static const String medicinesEndpoint = "$baseUrl/app/api/medicines/";

  // Authentication endpoints – adjust these to match your Django URLs
  static const String loginEndpoint = "$baseUrl/user/api/login/";
  static const String profileEndpoint = "$baseUrl/user/profile1/user/";

  // Token key for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    print('📡 Fetching user profile from: $userProfileEndpoint');

    final response = await http.get(
      Uri.parse(userProfileEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print('User profile fetch response status: ${response.statusCode}');
    print('User profile fetch response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token invalid/expired – clear it
      await clearToken();
      throw Exception('Authentication failed. Please log in again.');
    } else {
      throw Exception('Failed to load user profile: ${response.body}');
    }
  }
  // In api_service.dart

  // Get comments for a medicine - using String ID
  static Future<Map<String, dynamic>> getMedicineComments(
    String medicineId, { // UUID string
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final queryParams = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
    };

    // URL with String ID
    final uri = Uri.parse(
      '$baseUrl/app/api/medicines/$medicineId/comments/',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print('Get comments response status: ${response.statusCode}');
    print('Get comments response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  // Create a new comment
  static Future<Map<String, dynamic>> createComment(
    String medicineId, // UUID string
    String text,
  ) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/app/api/medicines/$medicineId/comments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'text': text}),
    );

    print('Create comment response status: ${response.statusCode}');
    print('Create comment response body: ${response.body}');

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create comment: ${response.body}');
    }
  }

  // Get comment statistics
  static Future<Map<String, dynamic>> getCommentStatistics(
    String medicineId, // UUID string
  ) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/app/api/medicines/$medicineId/comments/stats/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print('Comment stats response status: ${response.statusCode}');
    print('Comment stats response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return {
        'success': true,
        'statistics': {
          'total_comments': 0,
          'positive': 0,
          'negative': 0,
          'neutral': 0,
          'general': 0,
        },
      };
    } else {
      throw Exception('Failed to load comment statistics: ${response.body}');
    }
  } // Delete a comment

  static Future<void> deleteComment(int commentId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/app/comments/$commentId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print('Delete comment response status: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.body}');
    }
  }

  // Get comment statistics

  // --- Token management ---
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // --- Login ---
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user/api/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error message from response body
        String errorMsg = 'Server error (${response.statusCode})';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('message')) {
            errorMsg = errorData['message'];
          } else if (errorData.containsKey('error')) {
            errorMsg = errorData['error'];
          } else if (errorData.containsKey('detail')) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- Fetch profile (authenticated) ---
  static Future<Map<String, dynamic>> fetchProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse(profileEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token', // or 'Bearer $token' if using JWT
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token invalid/expired – clear it
      await clearToken();
      throw Exception('Authentication failed. Please log in again.');
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  // --- Logout (clear token) ---
  static Future<void> logout() async {
    await clearToken();
    // Optionally call a logout endpoint on the server
  }

  // --- Existing medicine fetching methods (unchanged) ---
  static Future<Map<String, dynamic>> fetchAllData({
    String? categorySlug,
    String? ingredientId,
  }) async {
    final uri = Uri.parse(medicinesEndpoint).replace(
      queryParameters: {
        if (categorySlug != null) 'category': categorySlug,
        if (ingredientId != null) 'ingredient': ingredientId,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load data");
    }
  }

  // In ApiService.dart - update the profile endpoint
  // Changed from profile1/user/ to user/user/

  // New registration method
  static Future<void> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/NewRegister/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Registration failed: ${response.body}');
    }
    // If needed, you can return the response body, but here we just check success
  }

  // New OTP verification method
  static Future<void> verifyOtp(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': code}),
    );
    if (response.statusCode != 200) {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  static Future<List<Medicine>> fetchMedicines() async {
    final data = await fetchAllData();
    List medicinesJson = data['medicines'] ?? [];
    return medicinesJson.map((e) => Medicine.fromJson(e)).toList();
  }
  // في ApiService - دوال المحفظة

  static Future<Map<String, dynamic>> getWallet(String token) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/app/api/wallet/'), // المسار صحيح كما هو
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load wallet: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> addMoney({
    required String token,
    required String type,
    required double amount,
    String? code,
    String? accountNumber,
    File? image,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/app/api/wallet/add/'),
    );

    request.headers['Authorization'] = 'Token $token'; // ✅ استخدم Token

    request.fields['type'] = type;
    request.fields['amount'] = amount.toString();
    if (code != null) request.fields['code'] = code;
    if (accountNumber != null) request.fields['account_number'] = accountNumber;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add money: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> withdrawMoney({
    required String token,
    required String type,
    required double amount,
    required String accountNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/api/wallet/withdraw/'),
      headers: {
        'Authorization': 'Token $token', // ✅ استخدم Token
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': type,
        'amount': amount,
        'account_number': accountNumber,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to withdraw money: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getOperations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/app/api/wallet/operations/'),
      headers: {
        'Authorization': 'Token $token', // ✅ استخدم Token
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load operations: ${response.body}');
    }
  }
  // services/api_service.dart (add these methods)

  static Future<Map<String, dynamic>> getChatUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/api/chat/users/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat users');
    }
  }

  static Future<Map<String, dynamic>> getChatMessages(
    String token,
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/api/chat/messages/$userId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String token,
    int recipientId,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/api/chat/send/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'recipient_id': recipientId, 'content': content}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }

  static Future<Map<String, dynamic>> cancelOperation(
    String token,
    int operationId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/api/wallet/operations/$operationId/cancel/'),
      headers: {
        'Authorization': 'Token $token', // ✅ استخدم Token
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to cancel operation: ${response.body}');
    }
  }
}

// lib/services/address_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address.dart';

class AddressService {
  static const String baseUrl = 'http://192.168.137.1:8000/app/api';

  final String token;

  AddressService(this.token);

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token', // ✅ Change from 'Bearer' to 'Token'
    };
  }

  // Get all addresses
  Future<List<Address>> getAddresses() async {
    try {
      print('📡 Fetching addresses from: $baseUrl/addresses/');
      print('🔑 Using token: ${token.substring(0, min(10, token.length))}...');

      final response = await http.get(
        Uri.parse('$baseUrl/addresses/'),
        headers: _getHeaders(),
      );

      print('Addresses response status: ${response.statusCode}');
      print('Addresses response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> addressesJson = data['addresses'];
        return addressesJson.map((json) => Address.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to load addresses: ${response.body}');
      }
    } catch (e) {
      print('Error in getAddresses: $e');
      throw Exception('Error: $e');
    }
  }

  // Create address
  Future<Address> createAddress(Address address) async {
    try {
      print('📡 Creating address at: $baseUrl/addresses/');
      print('Address data: ${address.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/addresses/'),
        headers: _getHeaders(),
        body: json.encode(address.toJson()),
      );

      print('Create address response status: ${response.statusCode}');
      print('Create address response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Address.fromJson(data['address']);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors'] ?? 'Failed to create address');
      }
    } catch (e) {
      print('Error in createAddress: $e');
      throw Exception('Error: $e');
    }
  }

  // Update address
  Future<Address> updateAddress(String id, Address address) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/addresses/$id/'),
        headers: _getHeaders(),
        body: json.encode(address.toJson()),
      );

      print('Update address response status: ${response.statusCode}');
      print('Update address response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data['address']);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors'] ?? 'Failed to update address');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete address
  Future<void> deleteAddress(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$id/'),
        headers: _getHeaders(),
      );

      print('Delete address response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Set default address
  Future<Address> setDefaultAddress(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses/$id/set-default/'),
        headers: _getHeaders(),
      );

      print('Set default address response status: ${response.statusCode}');
      print('Set default address response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Address.fromJson(data['address']);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to set default address');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

// Helper function
int min(int a, int b) => a < b ? a : b;

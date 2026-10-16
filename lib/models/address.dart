// lib/models/address.dart
class Address {
  final String id;
  final int user;
  final String label;
  final String addressLine;
  final String city;
  final String postalCode;
  final String phone;
  final bool isDefault;
  final double x; // Longitude
  final double y; // Latitude

  Address({
    required this.id,
    required this.user,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    required this.phone,
    required this.isDefault,
    required this.x,
    required this.y,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      user: json['user'],
      label: json['label'] ?? '',
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['is_default'] ?? false,
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'address_line': addressLine,
      'city': city,
      'postal_code': postalCode,
      'phone': phone,
      'is_default': isDefault,
      'x': x,
      'y': y,
    };
  }

  Address copyWith({
    String? id,
    int? user,
    String? label,
    String? addressLine,
    String? city,
    String? postalCode,
    String? phone,
    bool? isDefault,
    double? x,
    double? y,
  }) {
    return Address(
      id: id ?? this.id,
      user: user ?? this.user,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

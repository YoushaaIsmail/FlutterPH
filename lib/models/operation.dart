// models/operation.dart
class Operation {
  final int id;
  final String type;
  final String method;
  final double amount;
  final String? code;
  final String? image;
  final String date1;
  final String? date2;
  final int walletId;
  final String state;
  final String? account;

  Operation({
    required this.id,
    required this.type,
    required this.method,
    required this.amount,
    this.code,
    this.image,
    required this.date1,
    this.date2,
    required this.walletId,
    required this.state,
    this.account,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'],
      type: json['type'] ?? '',
      method: json['Method'] ?? '',
      amount: (json['Amount'] ?? 0.0).toDouble(),
      code: json['code'],
      image: json['image'],
      date1: json['Date1'] ?? '',
      date2: json['Date2'],
      walletId: json['MyAccount'],
      state: json['state'] ?? 'pending',
      account: json['Account'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'Method': method,
      'Amount': amount,
      'code': code,
      'image': image,
      'Date1': date1,
      'Date2': date2,
      'MyAccount': walletId,
      'state': state,
      'Account': account,
    };
  }
}

// models/wallet.dart
class Wallet {
  final int id;
  final String username;
  final double amount;
  final int userId;

  Wallet({
    required this.id,
    required this.username,
    required this.amount,
    required this.userId,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      username: json['username'] ?? '',
      amount: (json['Amount'] ?? 0.0).toDouble(),
      userId: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'Amount': amount, 'user': userId};
  }
}
